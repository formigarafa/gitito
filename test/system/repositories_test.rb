require "application_system_test_case"

class RepositoriesTest < ApplicationSystemTestCase
  setup do
    @user = users(:juca)
    sign_in_as @user
  end

  test "a user creates a repository" do
    visit repositories_path
    click_on "New"
    fill_in "Name", with: "my-project"
    click_on "Save"

    assert_text "Repository was successfully created."
    repository = @user.repositories.find_by!(name: "my-project")
    assert_current_path repository_path(repository)
    assert_selector "h2", text: "my-project"
    assert_text repository.url
    assert_stored repository

    click_on "List"
    assert_link repository.url
  end

  test "a user deletes a repository" do
    repository = @user.repositories.create!(name: "my-project")

    visit repository_path(repository)
    confirm_dialog("Are you sure?") { click_on "Delete" }

    assert_text "Repository was successfully destroyed."
    assert_current_path repositories_path
    assert_no_link repository.url
    assert_not_stored repository
  end
end
