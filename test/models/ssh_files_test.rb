require "test_helper"

class SshFilesTest < ActiveSupport::TestCase
  setup do
    @tmp_dir = Dir.mktmpdir
    @authorized_keys = "#{@tmp_dir}/authorized_keys"
    @proxy_config = "#{@tmp_dir}/proxy.conf"
  end

  teardown do
    FileUtils.remove_entry @tmp_dir
  end

  def sync(authorized_keys: @authorized_keys, proxy_config: @proxy_config)
    SshFiles.new(authorized_keys: authorized_keys, proxy_config: proxy_config).sync
  end

  def add_key(user = users(:juca))
    user.user_credentials.create!(key: ssh_key(user.username))
  end

  def line_of(credential)
    "command=\"#{Rails.root}/script/ssh-command-proxy.sh #{credential.id}\" #{credential.key}"
  end

  # The lines gitito keeps in the authorized keys file for +credentials+.
  def block_of(*credentials)
    [ SshFiles::BLOCK_BEGIN, *credentials.map { |credential| line_of(credential) }, SshFiles::BLOCK_END ]
  end

  def authorized_keys_lines(path = @authorized_keys)
    File.readlines(path, chomp: true)
  end

  def mode_of(path)
    File.stat(path).mode.to_s(8)[-3..]
  end

  # The authorized keys file

  test "writes an empty block without user credentials" do
    sync

    assert_equal block_of, authorized_keys_lines
  end

  test "writes one line for each user credential, forcing it to run the script with its id" do
    credentials = [ add_key, add_key(users(:drica)) ]

    sync

    assert_equal block_of(*credentials.sort_by(&:id)), authorized_keys_lines
  end

  test "leaves out a user credential holding what is not a public key" do
    kept = add_key
    smuggled = add_key(users(:drica))
    smuggled.update_column :key, "#{smuggled.key}\n#{ssh_key('free to run anything')}"

    sync

    assert_equal block_of(kept), authorized_keys_lines
  end

  test "creates the folders of the authorized keys file with 700 mode" do
    sync authorized_keys: "#{@tmp_dir}/s1/s2/.ssh/authorized_keys"

    assert_equal "700", mode_of("#{@tmp_dir}/s1/s2/.ssh")
    assert_equal block_of, authorized_keys_lines("#{@tmp_dir}/s1/s2/.ssh/authorized_keys")
  end

  test "creates the authorized keys file with 644 mode" do
    previous_umask = File.umask 0
    begin
      sync

      assert_equal "644", mode_of(@authorized_keys)
    ensure
      File.umask previous_umask
    end
  end

  test "keeps the permissions the authorized keys file already had" do
    File.write @authorized_keys, "ssh-ed25519 AAAA admin@laptop\n", perm: 0o600

    sync

    assert_equal "600", mode_of(@authorized_keys)
  end

  test "leaves nothing but the two files behind" do
    sync

    assert_equal %w[authorized_keys proxy.conf], Dir.children(@tmp_dir).sort
  end

  test "writes through a link to the authorized keys file" do
    File.write "#{@tmp_dir}/real_keys", "ssh-ed25519 AAAA admin@laptop\n"
    File.symlink "#{@tmp_dir}/real_keys", @authorized_keys

    sync

    assert File.symlink?(@authorized_keys)
    assert_equal [ "ssh-ed25519 AAAA admin@laptop", *block_of ], authorized_keys_lines("#{@tmp_dir}/real_keys")
  end

  test "keeps the keys of others and adds its block after them" do
    File.write @authorized_keys, "# my own keys\nssh-ed25519 AAAA admin@laptop\n\nssh-rsa BBBB backup"
    credential = add_key

    sync

    assert_equal [ "# my own keys", "ssh-ed25519 AAAA admin@laptop", "", "ssh-rsa BBBB backup", *block_of(credential) ],
      authorized_keys_lines
    assert File.read(@authorized_keys).end_with?("\n")
  end

  test "rewrites its block where it is, keeping the keys around it" do
    stale = "command=\"#{Rails.root}/script/ssh-command-proxy.sh 999\" ssh-ed25519 AAAA stale"
    File.write @authorized_keys, [
      "ssh-ed25519 AAAA before", SshFiles::BLOCK_BEGIN, stale, "anything else", SshFiles::BLOCK_END, "ssh-ed25519 AAAA after"
    ].join("\n")
    credential = add_key

    sync

    assert_equal [ "ssh-ed25519 AAAA before", *block_of(credential), "ssh-ed25519 AAAA after" ], authorized_keys_lines
  end

  test "does not grow the authorized keys file when synced again" do
    File.write @authorized_keys, "ssh-ed25519 AAAA admin@laptop\n"
    add_key
    sync
    content = File.read(@authorized_keys)

    3.times { sync }

    assert_equal content, File.read(@authorized_keys)
  end

  test "moves the keys of a file written before the block existed into the block" do
    credential = add_key
    removed = "command=\"/somewhere/else/script/ssh-command-proxy.sh 999\" ssh-ed25519 AAAA removed"
    File.write @authorized_keys, "#{line_of(credential)}\nssh-ed25519 AAAA admin@laptop\n#{removed}\n"

    sync

    assert_equal [ "ssh-ed25519 AAAA admin@laptop", *block_of(credential) ], authorized_keys_lines
  end

  test "keeps the keys of others when its block was left without an end" do
    File.write @authorized_keys, "ssh-ed25519 AAAA before\n#{SshFiles::BLOCK_BEGIN}\nssh-ed25519 AAAA after\n"

    sync

    assert_equal [ "ssh-ed25519 AAAA before", "ssh-ed25519 AAAA after", *block_of ], authorized_keys_lines
  end

  # The config file of the script

  test "writes where to ask the app, the token to ask with and where the repositories are, readable only by its owner" do
    sync proxy_config: "#{@tmp_dir}/storage/proxy.conf"

    expected = [
      "url=#{Rails.configuration.gitito[:ssh_access_url]}/internal/ssh_access",
      "token=#{SshAccess.token}",
      "repositories=#{RepositoryStorage.default.root}"
    ]
    assert_equal expected, File.readlines("#{@tmp_dir}/storage/proxy.conf", chomp: true)
    assert_equal "600", mode_of("#{@tmp_dir}/storage/proxy.conf")
    assert_equal [ "proxy.conf" ], Dir.children("#{@tmp_dir}/storage")
  end

  # Where the app keeps them

  test "keeps the files where the app is configured to, the config file in storage for each environment" do
    previous = SshFiles.default
    SshFiles.default = nil

    assert_equal File.expand_path(Rails.configuration.gitito[:ssh_authorized_keys_file]), SshFiles.default.authorized_keys
    assert_predicate Pathname(SshFiles.default.authorized_keys), :absolute?
    assert_equal Rails.root.join("storage/ssh-command-proxy.test.conf").to_s, SshFiles.default.proxy_config
  ensure
    SshFiles.default = previous
  end

  test "syncs the files of the app" do
    credential = add_key
    FileUtils.rm_f [ SshFiles.default.authorized_keys, SshFiles.default.proxy_config ]

    SshFiles.sync

    assert_equal block_of(credential), authorized_keys_lines(SshFiles.default.authorized_keys)
    assert_path_exists SshFiles.default.proxy_config
  end
end
