module Internal
  # Answers script/ssh-command-proxy.sh in lines of name=value, as the script
  # reads its config file: 200 with the verb and the repository to run it on,
  # or 403 with the message for the client.
  class SshAccessController < ActionController::API
    before_action :require_token

    def create
      answer = SshAccess.decide(params[:credential_id], params[:command])

      if answer.granted?
        render plain: "verb=#{answer.verb}\nrepository=#{answer.repository}\n"
      else
        render plain: "message=#{answer.message}\n", status: :forbidden
      end
    end

    private

    def require_token
      head :unauthorized unless SshAccess.valid_token?(request.authorization.to_s.delete_prefix("Bearer "))
    end
  end
end
