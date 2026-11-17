require "test_helper"

class CollaboratorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @repository = repositories(:tilt)
    sign_in_as users(:formigarafa)
  end

  test "create adds the user as collaborator and redirects to the repository" do
    assert_difference -> { @repository.collaborators.count } do
      post repository_collaborators_path(@repository), params: { collaborator: { username: "juca" } }
    end
    assert_equal users(:juca), @repository.collaborators.last.user
    assert_redirected_to repository_path(@repository)
    assert_equal "Collaborator was successfully created.", flash[:notice]
  end

  test "create with an unknown username flashes the error and redirects to the repository" do
    assert_no_difference -> { Collaborator.count } do
      post repository_collaborators_path(@repository), params: { collaborator: { username: "nobody" } }
    end
    assert_redirected_to repository_path(@repository)
    assert_equal "User not found", flash[:error]
  end

  test "destroy removes the collaborator" do
    collaborator = @repository.collaborators.create!(user: users(:juca))
    assert_difference -> { Collaborator.count }, -1 do
      delete repository_collaborator_path(@repository, collaborator)
    end
    assert_redirected_to repository_path(@repository)
    assert_response :see_other
    assert_equal "Collaborator was successfully destroyed.", flash[:notice]
  end
end
