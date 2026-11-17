require "test_helper"

# Hotwire/Turbo only renders a failed form submission when it comes back as
# 422, and only follows redirects after non-GET requests when they are 303.
class TurboResponsesTest < ActionDispatch::IntegrationTest
  test "failed sign in renders the form with 422" do
    post session_path, params: { email: "nobody@example.com", password: "wrong" }
    assert_response :unprocessable_content
  end

  test "invalid repository renders the form with 422" do
    sign_in_as users(:juca)
    post repositories_path, params: { repository: { name: "not valid!" } }
    assert_response :unprocessable_content
  end

  test "deleting a user credential redirects with 303" do
    user = users(:juca)
    credential = UserCredential.stub(:generate_authorized_keys_file, nil) do
      user.user_credentials.create!(title: "laptop", key: "ssh-ed25519 AAAA laptop")
    end
    sign_in_as user

    UserCredential.stub(:generate_authorized_keys_file, nil) do
      delete user_credential_path(credential)
    end
    assert_response :see_other
  end
end
