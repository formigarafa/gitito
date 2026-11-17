require "test_helper"

class UserCredentialsViewsTest < ActionView::TestCase
  setup do
    controller.controller_path = "user_credentials"
  end

  def build_credentials
    [
      UserCredential.new(id: 1, title: "key one", key: "contents-key-one"),
      UserCredential.new(id: 2, title: "key two", key: "contents-key-two")
    ]
  end

  test "index displays both user credentials" do
    @user_credentials = build_credentials

    render template: "user_credentials/index"

    assert_match(/key one/, rendered)
    assert_match(/key two/, rendered)
  end

  test "index renders a delete button asking for confirmation for each credential" do
    @user_credentials = build_credentials

    render template: "user_credentials/index"

    assert_select "form.button_to[data-turbo-confirm]", count: 2 do
      assert_select "input[name=_method][value=delete]"
    end
  end

  test "new renders new user_credential form" do
    @user_credential = UserCredential.new

    render template: "user_credentials/new"

    assert_select "form[action=?][method=?]", user_credentials_path, "post"
  end

  test "edit renders the edit user_credential form" do
    @user_credential = UserCredential.create!(title: "key one", key: "contents-key-one", user: users(:juca))

    render template: "user_credentials/edit"

    assert_select "form[action=?][method=?]", user_credential_path(@user_credential), "post"
  end
end
