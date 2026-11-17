require "test_helper"

module Internal
  class SshAccessControllerTest < ActionDispatch::IntegrationTest
    setup do
      @owner_key = users(:formigarafa).user_credentials.create!(key: ssh_key("owner"))
      @other_key = users(:juca).user_credentials.create!(key: ssh_key("other"))
    end

    def ask(credential_id, command, token: SshAccess.token)
      post internal_ssh_access_path, params: { credential_id: credential_id, command: command },
        headers: { "Authorization" => "Bearer #{token}" }
    end

    test "answers the key of the owner with the command to run" do
      ask @owner_key.id, "git upload-pack '/formigarafa/tilt'"

      assert_response :ok
      assert_equal "text/plain", response.media_type
      assert_equal "verb=git-upload-pack\nrepository=formigarafa/tilt.git\n", response.body
    end

    test "answers the key of a collaborator with the command to run" do
      repositories(:tilt).collaborators.create!(user: users(:juca))

      ask @other_key.id, "git-receive-pack 'formigarafa/tilt.git'"

      assert_response :ok
      assert_equal "verb=git-receive-pack\nrepository=formigarafa/tilt.git\n", response.body
    end

    test "forbids the key of anyone else, with what to tell them" do
      ask @other_key.id, "git-upload-pack 'formigarafa/tilt.git'"

      assert_response :forbidden
      assert_equal "text/plain", response.media_type
      assert_equal "message=Repository not found or access denied\n", response.body
    end

    test "forbids a repository that does not exist the same way" do
      ask @owner_key.id, "git-upload-pack 'formigarafa/nothing.git'"

      assert_response :forbidden
      assert_equal "message=Repository not found or access denied\n", response.body
    end

    test "forbids what is not a git server command" do
      ask @owner_key.id, "ls"

      assert_response :forbidden
      assert_equal "message=Command not allowed\n", response.body
    end

    test "forbids when something is missing" do
      ask nil, "git-upload-pack 'formigarafa/tilt.git'"
      assert_response :forbidden

      ask @owner_key.id, nil
      assert_response :forbidden
    end

    test "refuses a wrong token" do
      ask @owner_key.id, "git-upload-pack 'formigarafa/tilt.git'", token: "wrong"

      assert_response :unauthorized
      assert_empty response.body
    end

    test "refuses a request without a token" do
      post internal_ssh_access_path, params: { credential_id: @owner_key.id, command: "git-upload-pack 'formigarafa/tilt.git'" }
      assert_response :unauthorized
    end

    test "does not accept the session of a signed in user as a token" do
      sign_in_as users(:formigarafa)

      post internal_ssh_access_path, params: { credential_id: @owner_key.id, command: "git-upload-pack 'formigarafa/tilt.git'" }
      assert_response :unauthorized
    end
  end
end
