# What script/ssh-command-proxy.sh needs to ask the app, on every SSH
# connection, whether a key can reach a repository.
module SshAccess
  REPOSITORY_PATH = %r{\A(?<owner>[^/]+)/(?<name>[^/]+)\.git\z}

  class << self
    # Can the key of +credential_id+ reach the repository at +path+, as in
    # "<owner>/<name>.git"?
    def allowed?(credential_id, path)
      user = UserCredential.find_by(id: credential_id)&.user
      repository = find_repository(path)

      user.present? && repository.present? && repository.accessible_by?(user)
    end

    def find_repository(path)
      match = REPOSITORY_PATH.match(path.to_s)
      match && Repository.joins(:user).find_by(name: match[:name], users: { username: match[:owner] })
    end

    # Shared with the script through the config file. Derived from the secret
    # key base, so there is nothing else to configure or to keep.
    def token
      Rails.application.key_generator.generate_key("gitito ssh access", 32).unpack1("H*")
    end

    def valid_token?(given)
      ActiveSupport::SecurityUtils.secure_compare(given.to_s, token)
    end

    def url
      "#{Rails.configuration.gitito[:ssh_access_url].chomp('/')}/internal/ssh_access"
    end

    # The script reads the production one, from beside the repositories.
    def config_path
      Rails.root.join("storage/ssh-command-proxy.#{Rails.env}.conf").to_s
    end

    # Only the user sshd runs the script as needs to read it.
    def write_config
      FileUtils.mkdir_p File.dirname(config_path)
      temporary_path = "#{config_path}.#{Process.pid}.tmp"
      File.write temporary_path, "url=#{url}\ntoken=#{token}\n", perm: 0o600
      File.rename temporary_path, config_path
    end
  end
end
