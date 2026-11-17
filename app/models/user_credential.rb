class UserCredential < ApplicationRecord
  belongs_to :user, optional: true
  validates :key, presence: true, uniqueness: true
  validates :user, presence: true

  def authorized_keys_line
    # command="script/ssh-command-proxy.sh" ssh-rsa <long_user_key_here>
    "command=\"#{Rails.root}/script/ssh-command-proxy.sh #{id}\" #{key}"
  end

  after_save do
    UserCredential.generate_authorized_keys_file
  end

  after_destroy do
    UserCredential.generate_authorized_keys_file
  end

  # The keys of gitito live between these two lines of the authorized keys
  # file. Whatever else is in the file belongs to someone else and is kept.
  BLOCK_BEGIN = "# BEGIN gitito keys. Managed by gitito: changes inside this block are lost."
  BLOCK_END = "# END gitito keys"

  # A line written by gitito, even when found outside the block, as in a file
  # written before the block existed.
  MANAGED_LINE = %r{\Acommand="[^"]*/script/ssh-command-proxy\.sh \d+" }

  class << self
    # Also writes what the forced command of the keys needs to reach the app.
    def generate_authorized_keys_file
      SshAccess.write_config

      path = authorized_keys_absolute_path
      FileUtils.mkdir_p(File.dirname(path), mode: 0o700)
      path = File.realpath(path) if File.exist?(path)
      before, after = lines_around_block(File.exist?(path) ? File.readlines(path, chomp: true) : [])
      lines = [ *before, BLOCK_BEGIN, *UserCredential.find_each.map(&:authorized_keys_line), BLOCK_END, *after ]

      replace_file path, lines.map { |line| "#{line}\n" }.join
    end

    def authorized_keys_absolute_path
      File.expand_path Rails.configuration.gitito[:ssh_authorized_keys_file]
    end

    private

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

    # Written aside and renamed, so sshd never reads a half written file, and
    # with the permissions the file already had.
    def replace_file(path, content)
      temporary_path = "#{path}.#{Process.pid}.tmp"
      File.write temporary_path, content, perm: 0o644
      File.chmod File.stat(path).mode & 0o777, temporary_path if File.exist?(path)
      File.rename temporary_path, path
    end
  end
end
