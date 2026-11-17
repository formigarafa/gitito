require "application_system_test_case"

class UserCredentialsTest < ApplicationSystemTestCase
  KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbFowboGDdo9nzNtsUuX/rvGsiOkd2BAXgvXcf2dipM juca@laptop".freeze

  setup do
    @user = users(:juca)
    sign_in_as @user
  end

  def authorized_keys
    File.read(SshFiles.default.authorized_keys)
  end

  test "a user adds a credential" do
    visit user_credentials_path
    click_on "New"
    fill_in "Title", with: "laptop"
    fill_in "Key", with: KEY
    click_on "Save"

    assert_text "User credential was successfully created."
    assert_current_path user_credentials_path
    assert_selector "td", text: "laptop"
    assert_includes authorized_keys, KEY
  end

  test "a user edits a credential" do
    @user.user_credentials.create!(title: "laptop", key: KEY)

    visit user_credentials_path
    click_on "Edit"
    fill_in "Title", with: "desktop"
    click_on "Save"

    assert_text "User credential was successfully updated."
    assert_selector "td", text: "desktop"
    assert_no_selector "td", text: "laptop"
  end

  test "a user deletes a credential" do
    @user.user_credentials.create!(title: "laptop", key: KEY)

    visit user_credentials_path
    confirm_dialog("Are you sure?", with: "Delete") { click_on "Delete" }

    assert_text "User credential was successfully destroyed."
    assert_no_selector "td", text: "laptop"
    assert_not_includes authorized_keys, KEY
  end
end
