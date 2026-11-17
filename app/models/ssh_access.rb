# The answer to what script/ssh-command-proxy.sh asks the app on every SSH
# connection: can this key reach this repository?
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

    # Shared with the script through the config file SshFiles writes. Derived
    # from the secret key base, so there is nothing else to configure or keep.
    def token
      Rails.application.key_generator.generate_key("gitito ssh access", 32).unpack1("H*")
    end

    def valid_token?(given)
      ActiveSupport::SecurityUtils.secure_compare(given.to_s, token)
    end
  end
end
