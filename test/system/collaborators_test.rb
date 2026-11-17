require "application_system_test_case"

class CollaboratorsTest < ApplicationSystemTestCase
  setup do
    @repository = repositories(:tilt)
    sign_in_as users(:formigarafa)
  end

  test "an owner adds a collaborator to a repository" do
    visit repository_path(@repository)
    fill_in "Add a collaborator", with: "juca"
    click_on "Add"

    assert_text "juca is now a collaborator."
    assert_current_path repository_path(@repository)
    assert_selector ".collaborators .collaborator", text: "juca"
    assert_equal [ users(:juca) ], @repository.collaborators.map(&:user)
  end

  test "an owner removes a collaborator from a repository" do
    @repository.collaborators.create!(user: users(:juca))

    visit repository_path(@repository)
    assert_selector ".collaborators .collaborator", text: "juca"
    confirm_dialog("Remove juca?", with: "Remove") { click_on "Remove" }

    assert_text "juca is no longer a collaborator."
    assert_no_selector ".collaborators .collaborator"
    assert_empty @repository.collaborators.reload
  end
end
