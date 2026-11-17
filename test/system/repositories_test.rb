require "application_system_test_case"

class RepositoriesTest < ApplicationSystemTestCase
  setup do
    @user = users(:juca)
    sign_in_as @user
  end

  test "a user creates a repository" do
    visit repositories_path
    click_on "New repository", match: :first
    fill_in "Name", with: "my-project"
    click_on "Create repository"

    assert_text "Repository my-project was created."
    repository = @user.repositories.find_by!(name: "my-project")
    assert_current_path repository_path(repository)
    assert_selector "h1", text: "my-project"
    assert_text repository.url
    assert_stored repository

    click_on "All repositories"
    assert_link "my-project"
    assert_text repository.url
  end

  test "a user deletes a repository" do
    repository = @user.repositories.create!(name: "my-project")

    visit repository_path(repository)
    confirm_dialog("Delete my-project?", with: "Delete repository") { click_on "Delete repository" }

    assert_text "Repository my-project was deleted."
    assert_current_path repositories_path
    assert_no_text repository.url
    assert_not_stored repository
  end
end
