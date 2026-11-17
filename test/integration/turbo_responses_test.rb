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
    credential = user.user_credentials.create!(title: "laptop", key: ssh_key("laptop"))
    sign_in_as user

    delete user_credential_path(credential)
    assert_response :see_other
  end
end
