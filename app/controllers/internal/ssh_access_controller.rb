module Internal
  # Answers script/ssh-command-proxy.sh: 204 when the key can reach the
  # repository, 403 when it cannot, whether the repository exists or not.
  class SshAccessController < ActionController::API
    before_action :require_token

    def show
      head SshAccess.allowed?(params[:credential_id], params[:repository]) ? :no_content : :forbidden
    end

    private

    def require_token
      head :unauthorized unless SshAccess.valid_token?(request.authorization.to_s.delete_prefix("Bearer "))
    end
  end
end
