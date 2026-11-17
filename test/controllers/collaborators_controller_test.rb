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


  test "create requires authentication" do
    sign_out

    assert_no_difference -> { Collaborator.count } do
      post repository_collaborators_path(@repository), params: { collaborator: { username: "juca" } }
    end
    assert_redirected_to new_session_path
  end

  test "create does not add the owner as collaborator" do
    assert_no_difference -> { Collaborator.count } do
      post repository_collaborators_path(@repository), params: { collaborator: { username: "formigarafa" } }
    end
    assert_redirected_to repository_path(@repository)
    assert_equal "Repository owner cannot be also a collaborator", flash[:error]
  end

  test "create does not add the same collaborator twice" do
    @repository.collaborators.create!(user: users(:juca))

    assert_no_difference -> { Collaborator.count } do
      post repository_collaborators_path(@repository), params: { collaborator: { username: "juca" } }
    end
    assert_redirected_to repository_path(@repository)
    assert_equal "Collaborator is already on the list", flash[:error]
  end

  test "create shows the error on the repository page" do
    post repository_collaborators_path(@repository), params: { collaborator: { username: "nobody" } }
    follow_redirect!

    assert_select ".flash .message.error", text: "User not found"
  end

  test "create without a username is a bad request" do
    post repository_collaborators_path(@repository)
    assert_response :bad_request
  end

  test "create does not find an unknown repository" do
    post repository_collaborators_path(0), params: { collaborator: { username: "juca" } }
    assert_response :not_found
  end

  test "create does not add collaborators to repositories of other users" do
    sign_in_as users(:juca)

    assert_no_difference -> { Collaborator.count } do
      post repository_collaborators_path(@repository), params: { collaborator: { username: "drica.silva" } }
    end
    assert_response :not_found
  end

  test "destroy requires authentication" do
    collaborator = @repository.collaborators.create!(user: users(:juca))
    sign_out

    assert_no_difference -> { Collaborator.count } do
      delete repository_collaborator_path(@repository, collaborator)
    end
    assert_redirected_to new_session_path
  end

  test "destroy does not find collaborators of another repository" do
    collaborator = repositories(:rails).collaborators.create!(user: users(:juca))

    assert_no_difference -> { Collaborator.count } do
      delete repository_collaborator_path(@repository, collaborator)
    end
    assert_response :not_found
  end

  test "destroy does not remove collaborators from repositories of other users" do
    collaborator = @repository.collaborators.create!(user: users(:drica))
    sign_in_as users(:juca)

    assert_no_difference -> { Collaborator.count } do
      delete repository_collaborator_path(@repository, collaborator)
    end
    assert_response :not_found
  end
end
