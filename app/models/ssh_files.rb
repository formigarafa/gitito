# The two files sshd relies on to let the keys of the users reach their
# repositories: the authorized keys file, where every key is forced to run
# script/ssh-command-proxy.sh, and the config file that tells the script where
# to ask the app, the token to ask with, and where the repositories are kept.
class SshFiles
  # The keys of gitito live between these two lines of the authorized keys
  # file. Whatever else is in the file belongs to someone else and is kept.
  BLOCK_BEGIN = "# BEGIN gitito keys. Managed by gitito: changes inside this block are lost."
  BLOCK_END = "# END gitito keys"

  # A line written by gitito, even when found outside the block, as in a file
  # written before the block existed.
  MANAGED_LINE = %r{\Acommand="[^"]*/script/ssh-command-proxy\.sh \d+" }

  class << self
    attr_writer :default

    # The files where the app is configured to keep them. The script reads the
    # production config file, from beside the repositories.
    def default
      @default ||= new(
        authorized_keys: File.expand_path(Rails.configuration.gitito[:ssh_authorized_keys_file]),
        proxy_config: Rails.root.join("storage/ssh-command-proxy.#{Rails.env}.conf").to_s,
      )
    end

    def sync
      default.sync
    end
  end

  attr_reader :authorized_keys, :proxy_config

  def initialize(authorized_keys:, proxy_config:)
    @authorized_keys = authorized_keys
    @proxy_config = proxy_config
  end

  # Rewrites both files from the user credentials and the configuration of
  # the app. The config file goes first: the keys are of no use without it.
  def sync
    write_proxy_config
    write_authorized_keys
  end

  private

  # Only the user sshd runs the script as needs to read it.
  def write_proxy_config
    FileUtils.mkdir_p File.dirname(proxy_config)
    replace_file proxy_config, proxy_config_lines.map { |line| "#{line}\n" }.join, perm: 0o600
  end

  def proxy_config_lines
    [ "url=#{access_url}", "token=#{SshAccess.token}", "repositories=#{RepositoryStorage.default.root}" ]
  end

  def access_url
    "#{Rails.configuration.gitito[:ssh_access_url].chomp('/')}/internal/ssh_access"
  end

  def write_authorized_keys
    FileUtils.mkdir_p File.dirname(authorized_keys), mode: 0o700
    path = File.exist?(authorized_keys) ? File.realpath(authorized_keys) : authorized_keys
    before, after = lines_around_block(File.exist?(path) ? File.readlines(path, chomp: true) : [])
    lines = [ *before, BLOCK_BEGIN, *UserCredential.find_each.map { |credential| line_of(credential) }, BLOCK_END, *after ]

    replace_file path, lines.map { |line| "#{line}\n" }.join, perm: 0o644, keep_perm: true
  end

  # command="<app>/script/ssh-command-proxy.sh <user credential id>" <key>
  def line_of(credential)
    "command=\"#{Rails.root}/script/ssh-command-proxy.sh #{credential.id}\" #{credential.key}"
  end

  # The lines of others before and after the block. Without a complete
  # block, all of them come before it: the block goes to the end of the file.
  def lines_around_block(lines)
    first = lines.index(BLOCK_BEGIN)
    last = first && lines[first..].index(BLOCK_END)&.+(first)
    before, after = last ? [ lines[...first], lines[(last + 1)..] ] : [ lines, [] ]

    [ before, after ].map { |part| part.reject { |line| managed?(line) } }
  end

  def managed?(line)
    line == BLOCK_BEGIN || line == BLOCK_END || line.match?(MANAGED_LINE)
  end

  # Written aside and renamed, so nothing ever reads a half written file.
  # With keep_perm, a file that is already there keeps its permissions.
  def replace_file(path, content, perm:, keep_perm: false)
    temporary_path = "#{path}.#{Process.pid}.tmp"
    File.write temporary_path, content, perm: perm
    File.chmod File.stat(path).mode & 0o777, temporary_path if keep_perm && File.exist?(path)
    File.rename temporary_path, path
  end
end
