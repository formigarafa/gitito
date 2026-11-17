require "test_helper"

class UserCredentialTest < ActiveSupport::TestCase
  BASE64_CHARSET = [ *"a".."z", *"A".."Z", *"0".."9", "+", "/" ].freeze

  def valid_credential
    key = "ssh-rsa #{Array.new(372) { BASE64_CHARSET.sample }.join} user@comment.part.com"
    UserCredential.new(
      title: "test key",
      key: key,
      user: users(:juca),
    )
  end

  # Points the authorized_keys file at +path+ for the duration of the block.
  def with_authorized_keys_at(path, &)
    UserCredential.stub(:authorized_keys_absolute_path, path, &)
  end

  # The lines gitito keeps in the file for +credentials+.
  def block_of(*credentials)
    [ UserCredential::BLOCK_BEGIN, *credentials.map(&:authorized_keys_line), UserCredential::BLOCK_END ]
  end

  test "validates with valid attributes" do
    assert_predicate valid_credential, :valid?
  end

  test "fails with no user" do
    credential = valid_credential
    credential.user = nil
    assert_not credential.valid?
  end

  test "fails with no key" do
    credential = valid_credential
    credential.key = ""
    assert_not credential.valid?
  end

  test "fails for duplicated keys" do
    user = users(:juca)
    key = [
      "ssh-rsa ",
      "AAAAB3NzaC1yc2EAAAADAQABAAABAQC4d8XdRasriu5HA/GrmNv6wM50TioIgjsW/NcuVnH",
      "fuF29SGZkb1mjodDkKVP7BboGIfyE1SG4mgAxv8VGtN3FBtSZPWPCD1zOGwg/uFgbugYgWR",
      "Lg8IVKoSdDSgG7YwdLF7fktjpUCidFAaYCBnkzDkw+tWt9y79IdgokRwK+bmVuf80xXAr6m",
      "D9WLNqTxqXdmCHd9cMePzszdIVUtjIk0R/YHaoCZat+T2D+ICLs2oz2lv+4z5A6who82u6d",
      "0X5HDV7dIxf5s8rb/8HGbU1hshsK7VE6SXzph/dj7otkl4Mq4bJ3yLx6l7YktZ9hmVsn+S0",
      "zKcnlasD+ND2LM30X user@comment.part.com"
    ].join

    credential1 = valid_credential
    credential1.key = key
    credential1.user = user
    UserCredential.stub(:generate_authorized_keys_file, nil) do
      assert credential1.save
    end

    credential2 = valid_credential
    credential2.user = user
    credential2.key = key

    assert_not credential2.valid?
  end

  # ref: http://stackoverflow.com/questions/2494450/ssh-rsa-public-key-validation-using-a-regular-expression
  # latter, dont'botter me, yet.
  # test "fails with no spaces separating fields"
  # test "fails when first field not in [ssh-rsa, ssh-dsa]"
  # test "fails when second field can't be base64 decoded"
  # test "fails when decoded second field has wrong leading"

  test "generates authorized_keys line with its key" do
    key = "ssh-rsa AAAAB3NzaC1yc2EA#{'A' * 356}"
    credential = UserCredential.new key: key
    expected_line = "command=\"#{Rails.root}/script/ssh-command-proxy.sh 42\" #{key}"

    credential.stub(:id, "42") do
      assert_equal expected_line, credential.authorized_keys_line
    end
  end

  test "responds to generate_authorized_keys_file" do
    assert_respond_to UserCredential, :generate_authorized_keys_file
  end

  test "create folders with 700 mode when specified path doed not exists" do
    Dir.mktmpdir do |tmp_dir|
      auth_keys_file = "#{tmp_dir}/s1/s2/.ssh/authorized_keys"
      auth_keys_folder = File.dirname auth_keys_file

      with_authorized_keys_at(auth_keys_file) do
        assert_not File.exist?(auth_keys_folder)
        UserCredential.generate_authorized_keys_file
      end

      assert_path_exists auth_keys_folder
      assert_equal "700", File.stat(auth_keys_folder).mode.to_s(8)[-3..]
    end
  end

  test "generates an empty block with no user credential records" do
    Dir.mktmpdir do |tmp_dir|
      auth_keys_file = "#{tmp_dir}/s1/s2/.ssh/authorized_keys"

      with_authorized_keys_at(auth_keys_file) do
        assert_not File.exist?(auth_keys_file)
        UserCredential.generate_authorized_keys_file
      end

      assert_equal block_of, File.readlines(auth_keys_file, chomp: true)
    end
  end

  test "file generated with 644 mode" do
    previous_umask = File.umask 0
    begin
      Dir.mktmpdir do |tmp_dir|
        auth_keys_file = "#{tmp_dir}/.ssh/authorized_keys"

        with_authorized_keys_at(auth_keys_file) do
          assert_not File.exist?(auth_keys_file)
          UserCredential.generate_authorized_keys_file
        end

        assert_equal "644", File.stat(auth_keys_file).mode.to_s(8)[-3..]
      end
    ensure
      File.umask previous_umask
      assert_equal "22", File.umask.to_s(8)
    end
  end

  test "generates one line for each credential record" do
    Dir.mktmpdir do |tmp_dir|
      auth_keys_file = "#{tmp_dir}/authorized_keys"

      with_authorized_keys_at(auth_keys_file) do
        credentials = [ valid_credential, valid_credential ].each(&:save!)

        assert_equal block_of(*credentials.sort_by(&:id)), File.readlines(auth_keys_file, chomp: true)
      end
    end
  end

  test "keeps the keys of others and adds its block after them" do
    Dir.mktmpdir do |tmp_dir|
      auth_keys_file = "#{tmp_dir}/authorized_keys"
      File.write(auth_keys_file, "# my own keys\nssh-ed25519 AAAA admin@laptop\n\nssh-rsa BBBB backup")

      with_authorized_keys_at(auth_keys_file) do
        credential = valid_credential
        credential.save!

        assert_equal [ "# my own keys", "ssh-ed25519 AAAA admin@laptop", "", "ssh-rsa BBBB backup", *block_of(credential) ],
          File.readlines(auth_keys_file, chomp: true)
        assert File.read(auth_keys_file).end_with?("\n")
      end
    end
  end

  test "rewrites its block where it is, keeping the keys around it" do
    Dir.mktmpdir do |tmp_dir|
      auth_keys_file = "#{tmp_dir}/authorized_keys"
      stale = "command=\"#{Rails.root}/script/ssh-command-proxy.sh 999\" ssh-ed25519 AAAA stale"
      File.write auth_keys_file, [ "ssh-ed25519 AAAA before", *block_of, "ssh-ed25519 AAAA after" ].join("\n")
      File.write auth_keys_file, File.read(auth_keys_file).sub(UserCredential::BLOCK_END, "#{stale}\nanything else\n#{UserCredential::BLOCK_END}")

      with_authorized_keys_at(auth_keys_file) do
        credential = valid_credential
        credential.save!

        assert_equal [ "ssh-ed25519 AAAA before", *block_of(credential), "ssh-ed25519 AAAA after" ],
          File.readlines(auth_keys_file, chomp: true)
      end
    end
  end

  test "does not grow the file when generated again" do
    Dir.mktmpdir do |tmp_dir|
      auth_keys_file = "#{tmp_dir}/authorized_keys"
      File.write(auth_keys_file, "ssh-ed25519 AAAA admin@laptop\n")

      with_authorized_keys_at(auth_keys_file) do
        valid_credential.save!
        content = File.read(auth_keys_file)
        3.times { UserCredential.generate_authorized_keys_file }

        assert_equal content, File.read(auth_keys_file)
      end
    end
  end

  test "moves the keys of a file written before the block existed into the block" do
    Dir.mktmpdir do |tmp_dir|
      auth_keys_file = "#{tmp_dir}/authorized_keys"

      with_authorized_keys_at(auth_keys_file) do
        credential = valid_credential
        credential.save!
        removed = "command=\"/somewhere/else/script/ssh-command-proxy.sh 999\" ssh-ed25519 AAAA removed"
        File.write auth_keys_file, "#{credential.authorized_keys_line}\nssh-ed25519 AAAA admin@laptop\n#{removed}\n"

        UserCredential.generate_authorized_keys_file

        assert_equal [ "ssh-ed25519 AAAA admin@laptop", *block_of(credential) ], File.readlines(auth_keys_file, chomp: true)
      end
    end
  end

  test "keeps the keys of others when its block was left without an end" do
    Dir.mktmpdir do |tmp_dir|
      auth_keys_file = "#{tmp_dir}/authorized_keys"
      File.write auth_keys_file, "ssh-ed25519 AAAA before\n#{UserCredential::BLOCK_BEGIN}\nssh-ed25519 AAAA after\n"

      with_authorized_keys_at(auth_keys_file) do
        UserCredential.generate_authorized_keys_file
      end

      assert_equal [ "ssh-ed25519 AAAA before", "ssh-ed25519 AAAA after", *block_of ], File.readlines(auth_keys_file, chomp: true)
    end
  end

  test "keeps the permissions the file already had" do
    Dir.mktmpdir do |tmp_dir|
      auth_keys_file = "#{tmp_dir}/authorized_keys"
      File.write auth_keys_file, "ssh-ed25519 AAAA admin@laptop\n", perm: 0o600

      with_authorized_keys_at(auth_keys_file) do
        UserCredential.generate_authorized_keys_file
      end

      assert_equal "600", File.stat(auth_keys_file).mode.to_s(8)[-3..]
      assert_equal [ "authorized_keys" ], Dir.children(tmp_dir)
    end
  end

  test "writes through a link to the file" do
    Dir.mktmpdir do |tmp_dir|
      File.write "#{tmp_dir}/real_keys", "ssh-ed25519 AAAA admin@laptop\n"
      File.symlink "#{tmp_dir}/real_keys", "#{tmp_dir}/authorized_keys"

      with_authorized_keys_at("#{tmp_dir}/authorized_keys") do
        UserCredential.generate_authorized_keys_file
      end

      assert File.symlink?("#{tmp_dir}/authorized_keys")
      assert_equal [ "ssh-ed25519 AAAA admin@laptop", *block_of ], File.readlines("#{tmp_dir}/real_keys", chomp: true)
    end
  end

  test "being created adds its line to the authorized_keys file" do
    Dir.mktmpdir do |tmp_dir|
      auth_keys_file = "#{tmp_dir}/authorized_keys"

      with_authorized_keys_at(auth_keys_file) do
        credential = valid_credential
        credential.save!

        assert_equal block_of(credential), File.readlines(auth_keys_file, chomp: true)
      end
    end
  end

  test "being updated changes its line on the authorized_keys file" do
    Dir.mktmpdir do |tmp_dir|
      auth_keys_file = "#{tmp_dir}/authorized_keys"

      with_authorized_keys_at(auth_keys_file) do
        credential = valid_credential
        credential.save!
        credential.update!(key: "ssh-ed25519 AAAA changed")

        expected_line = "command=\"#{Rails.root}/script/ssh-command-proxy.sh #{credential.id}\" ssh-ed25519 AAAA changed"
        assert_equal [ UserCredential::BLOCK_BEGIN, expected_line, UserCredential::BLOCK_END ],
          File.readlines(auth_keys_file, chomp: true)
      end
    end
  end

  test "being destroyed removes its line from the authorized_keys file" do
    Dir.mktmpdir do |tmp_dir|
      auth_keys_file = "#{tmp_dir}/authorized_keys"

      with_authorized_keys_at(auth_keys_file) do
        kept = valid_credential
        doomed = valid_credential
        [ kept, doomed ].each(&:save!)

        doomed.destroy!

        assert_equal block_of(kept), File.readlines(auth_keys_file, chomp: true)
      end
    end
  end

  test "failing to be saved leaves the authorized_keys file untouched" do
    Dir.mktmpdir do |tmp_dir|
      auth_keys_file = "#{tmp_dir}/authorized_keys"

      with_authorized_keys_at(auth_keys_file) do
        assert_not UserCredential.new(title: "no key", user: users(:juca)).save
      end

      assert_not File.exist?(auth_keys_file)
    end
  end

  test "expands the configured authorized_keys path" do
    configured = Rails.configuration.gitito[:ssh_authorized_keys_file]

    assert_equal File.expand_path(configured), UserCredential.authorized_keys_absolute_path
    assert_predicate Pathname(UserCredential.authorized_keys_absolute_path), :absolute?
  end

  test "does not require a title" do
    credential = valid_credential
    credential.title = nil
    assert_predicate credential, :valid?
  end
end
