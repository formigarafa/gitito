# The answer to what script/ssh-command-proxy.sh asks the app on every SSH
# connection: what should this key run for the command it sent?
module SshAccess
  # The git server commands: what git runs on the other side to fetch, to
  # push, and to download an archive.
  VERBS = %w[git-upload-pack git-receive-pack git-upload-archive].freeze

  # What the script runs: +verb+ on +repository+, as in "<owner>/<name>.git".
  Grant = Data.define(:verb, :repository) do
    def granted? = true
  end

  # What the script tells the client instead of running anything.
  Denial = Data.define(:message) do
    def granted? = false
  end

  COMMAND_NOT_ALLOWED = Denial.new(message: "Command not allowed")

  # The same for a repository that does not exist as for one out of reach, so
  # that the answer does not tell which repositories exist.
  REPOSITORY_NOT_FOUND = Denial.new(message: "Repository not found or access denied")

  class << self
    # A Grant when the key of +credential_id+ sent a git server command on a
    # repository its user can reach, a Denial otherwise. +command+ is what the
    # client asked sshd to run, as it came.
    def decide(credential_id, command)
      verb, path = parse(command.to_s)
      return COMMAND_NOT_ALLOWED unless VERBS.include?(verb)

      user = UserCredential.find_by(id: credential_id)&.user
      repository = Repository.find_by_relative_path(path)
      return REPOSITORY_NOT_FOUND unless user && repository&.accessible_by?(user)

      Grant.new(verb: verb, repository: repository.relative_path)
    end

    # Shared with the script through the config file SshFiles writes. Derived
    # from the secret key base, so there is nothing else to configure or keep.
    def token
      Rails.application.key_generator.generate_key("gitito ssh access", 32).unpack1("H*")
    end

    def valid_token?(given)
      ActiveSupport::SecurityUtils.secure_compare(given.to_s, token)
    end

    private

    # The verb and the path in +command+, whichever way git wrote them:
    # "git upload-pack" for "git-upload-pack", the path with or without
    # quotes, with a leading slash when it comes from an ssh:// URL, and with
    # or without ".git".
    def parse(command)
      command = "git-#{command.delete_prefix('git ')}" if command.start_with?("git ")
      verb, _, path = command.partition(" ")
      path = path[1..-2] if path.length >= 2 && path.start_with?("'") && path.end_with?("'")
      path = path.delete_prefix("/")
      path = "#{path}.git" unless path.end_with?(".git")

      [ verb, path ]
    end
  end
end
