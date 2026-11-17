require "test_helper"

module Internal
  class SshAccessControllerTest < ActionDispatch::IntegrationTest
    setup do
      @owner_key = users(:formigarafa).user_credentials.create!(key: "ssh-ed25519 AAAA owner")
      @other_key = users(:juca).user_credentials.create!(key: "ssh-ed25519 AAAA other")
    end

    def check(credential_id, repository, token: SshAccess.token)
      get internal_ssh_access_path, params: { credential_id: credential_id, repository: repository },
        headers: { "Authorization" => "Bearer #{token}" }
    end

    test "allows the key of the owner" do
      check @owner_key.id, "formigarafa/tilt.git"
      assert_response :no_content
    end

    test "allows the key of a collaborator" do
      repositories(:tilt).collaborators.create!(user: users(:juca))

      check @other_key.id, "formigarafa/tilt.git"
      assert_response :no_content
    end

    test "forbids the key of anyone else" do
      check @other_key.id, "formigarafa/tilt.git"
      assert_response :forbidden
    end

    test "forbids a collaborator of another repository" do
      repositories(:rails).collaborators.create!(user: users(:juca))

      check @other_key.id, "formigarafa/tilt.git"
      assert_response :forbidden
    end

    test "forbids a repository that does not exist the same way" do
      check @owner_key.id, "formigarafa/nothing.git"
      assert_response :forbidden
      assert_empty response.body
    end

    test "forbids a key that does not exist" do
      check 0, "formigarafa/tilt.git"
      assert_response :forbidden
    end

    test "forbids when something is missing" do
      check nil, "formigarafa/tilt.git"
      assert_response :forbidden

      check @owner_key.id, nil
      assert_response :forbidden
    end

    test "refuses a wrong token" do
      check @owner_key.id, "formigarafa/tilt.git", token: "wrong"
      assert_response :unauthorized
    end

    test "refuses a request without a token" do
      get internal_ssh_access_path, params: { credential_id: @owner_key.id, repository: "formigarafa/tilt.git" }
      assert_response :unauthorized
    end

    test "does not accept the session of a signed in user as a token" do
      sign_in_as users(:formigarafa)

      get internal_ssh_access_path, params: { credential_id: @owner_key.id, repository: "formigarafa/tilt.git" }
      assert_response :unauthorized
    end
  end
end
