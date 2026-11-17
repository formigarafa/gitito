require "application_system_test_case"

class RepositoriesTest < ApplicationSystemTestCase
  setup do
    @user = users(:juca)
    sign_in_as @user
  end

  # Keeps the repositories of the block in a temporary folder.
  def with_repos_root(&)
    Dir.mktmpdir do |tmp_dir|
      Repository.stub(:repos_root, tmp_dir, &)
    end
  end

  test "a user creates a repository" do
    with_repos_root do
      visit repositories_path
      click_on "New"
      fill_in "Name", with: "my-project"
      click_on "Save"

      assert_text "Repository was successfully created."
      repository = @user.repositories.find_by!(name: "my-project")
      assert_current_path repository_path(repository)
      assert_selector "h2", text: "my-project"
      assert_text repository.url
      assert repository.structure_ok?

      click_on "List"
      assert_link repository.url
    end
  end

  test "a user deletes a repository" do
    with_repos_root do
      repository = @user.repositories.create!(name: "my-project")

      visit repository_path(repository)
      accept_confirm("Are you sure?") { click_on "Delete" }

      assert_text "Repository was successfully destroyed."
      assert_current_path repositories_path
      assert_no_link repository.url
      assert_not repository.folder_exists?
    end
  end
end
