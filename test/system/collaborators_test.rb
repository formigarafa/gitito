require "application_system_test_case"

class CollaboratorsTest < ApplicationSystemTestCase
  setup do
    @repository = repositories(:tilt)
    sign_in_as users(:formigarafa)
  end

  test "an owner adds a collaborator to a repository" do
    visit repository_path(@repository)
    fill_in "collaborator", with: "juca"
    click_on "Add"

    assert_text "Collaborator was successfully created."
    assert_current_path repository_path(@repository)
    assert_selector ".collaborators .collaborator", text: "juca"
    assert_equal [ users(:juca) ], @repository.collaborators.map(&:user)
  end

  test "an owner removes a collaborator from a repository" do
    @repository.collaborators.create!(user: users(:juca))

    visit repository_path(@repository)
    assert_selector ".collaborators .collaborator", text: "juca"
    confirm_dialog("Are you sure you want to remove this collaborator?") { click_on "Remove" }

    assert_text "Collaborator was successfully destroyed."
    assert_no_selector ".collaborators .collaborator"
    assert_empty @repository.collaborators.reload
  end
end
