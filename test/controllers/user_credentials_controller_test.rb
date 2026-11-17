require "test_helper"

class UserCredentialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:juca)
    sign_in_as @user
  end

  def create_credential(user = @user)
    user.user_credentials.create!(title: "laptop", key: ssh_key)
  end

  test "index lists only own credentials" do
    own = create_credential
    other = create_credential(users(:drica))
    other.update_column(:title, "someone else")

    get user_credentials_path

    assert_response :success
    assert_match own.title, response.body
    assert_no_match other.title, response.body
  end

  test "new renders the form" do
    get new_user_credential_path
    assert_response :success
    assert_select "form[action=?]", user_credentials_path
  end

  test "create builds the credential for the current user" do
    assert_difference -> { @user.user_credentials.count } do
      post user_credentials_path, params: { user_credential: { title: "laptop", key: ssh_key("new") } }
    end
    assert_redirected_to user_credentials_path
    assert_response :see_other
    assert_equal "User credential was successfully created.", flash[:notice]
  end

  test "create with invalid params renders the form with 422" do
    assert_no_difference -> { UserCredential.count } do
      post user_credentials_path, params: { user_credential: { title: "laptop", key: "" } }
    end
    assert_response :unprocessable_content
    assert_select "#error_explanation"
  end

  test "edit renders the form for an own credential" do
    credential = create_credential
    get edit_user_credential_path(credential)
    assert_response :success
    assert_select "form[action=?]", user_credential_path(credential)
  end

  test "edit does not find credentials of other users" do
    credential = create_credential(users(:drica))
    get edit_user_credential_path(credential)
    assert_response :not_found
  end

  test "update changes the credential" do
    credential = create_credential
    patch user_credential_path(credential), params: { user_credential: { title: "desktop" } }
    assert_redirected_to user_credentials_path
    assert_response :see_other
    assert_equal "desktop", credential.reload.title
    assert_equal "User credential was successfully updated.", flash[:notice]
  end

  test "update with invalid params renders the form with 422" do
    credential = create_credential
    patch user_credential_path(credential), params: { user_credential: { key: "" } }
    assert_response :unprocessable_content
    assert_select "#error_explanation"
  end

  test "destroy removes the credential and redirects to the list" do
    credential = create_credential
    assert_difference -> { UserCredential.count }, -1 do
      delete user_credential_path(credential)
    end
    assert_redirected_to user_credentials_path
    assert_response :see_other
  end

  test "destroy does not find credentials of other users" do
    credential = create_credential(users(:drica))
    assert_no_difference -> { UserCredential.count } do
      delete user_credential_path(credential)
    end
    assert_response :not_found
  end


  test "every action requires authentication" do
    credential = create_credential
    sign_out

    get user_credentials_path
    assert_redirected_to new_session_path
    get new_user_credential_path
    assert_redirected_to new_session_path
    get edit_user_credential_path(credential)
    assert_redirected_to new_session_path

    assert_no_changes -> { UserCredential.order(:id).pluck(:id, :title) } do
      post user_credentials_path, params: { user_credential: { title: "anonymous", key: ssh_key("anonymous") } }
      assert_redirected_to new_session_path
      patch user_credential_path(credential), params: { user_credential: { title: "anonymous" } }
      assert_redirected_to new_session_path
      delete user_credential_path(credential)
      assert_redirected_to new_session_path
    end
  end

  test "the root path lists the credentials" do
    own = create_credential

    get root_path

    assert_response :success
    assert_select "a[href=?]", edit_user_credential_path(own)
  end

  test "index shows long keys truncated" do
    credential = create_credential
    credential.update_column(:key, "ssh-ed25519 #{'A' * 80}")

    get user_credentials_path

    assert_match credential.key.truncate(50), response.body
    assert_no_match credential.key, response.body
  end

  test "create ignores an owner given in the params" do
    post user_credentials_path,
      params: { user_credential: { title: "laptop", key: ssh_key("mine"), user_id: users(:drica).id } }

    assert_equal @user, UserCredential.find_by!(title: "laptop").user
  end

  test "create with a key already in use renders the form with 422" do
    taken = create_credential(users(:drica))

    assert_no_difference -> { UserCredential.count } do
      post user_credentials_path, params: { user_credential: { title: "copy", key: taken.key } }
    end
    assert_response :unprocessable_content
    assert_select "#error_explanation li", text: "Key has already been taken"
  end

  test "create without credential params is a bad request" do
    post user_credentials_path
    assert_response :bad_request
  end

  test "update does not find credentials of other users" do
    credential = create_credential(users(:drica))

    patch user_credential_path(credential), params: { user_credential: { title: "hacked" } }

    assert_response :not_found
    assert_equal "laptop", credential.reload.title
  end

  # The keys in the authorized_keys file, without what sshd is told to run.
  def keys_in_authorized_keys
    File.readlines(SshFiles.default.authorized_keys, chomp: true).grep_v(/\A#/).map { |line| line.sub(/\Acommand="[^"]*" /, "") }
  end

  test "create, update and destroy keep the authorized_keys file up to date" do
    first, second = ssh_key("first"), ssh_key("second")

    post user_credentials_path, params: { user_credential: { title: "laptop", key: first } }
    credential = @user.user_credentials.find_by!(key: first)
    assert_equal [ first ], keys_in_authorized_keys

    patch user_credential_path(credential), params: { user_credential: { key: second } }
    assert_equal [ second ], keys_in_authorized_keys

    delete user_credential_path(credential)
    assert_empty keys_in_authorized_keys
  end
end
