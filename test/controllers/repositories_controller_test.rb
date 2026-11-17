require "test_helper"

class RepositoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:formigarafa)
    sign_in_as @owner
  end

  test "index lists own and collaborative repositories" do
    shared = users(:juca).repositories.create!(name: "shared-#{SecureRandom.hex(4)}")
    shared.collaborators.create!(user: @owner)

    get repositories_path

    assert_response :success
    assert_match repositories(:tilt).url, response.body
    assert_match shared.url, response.body
  end

  test "index does not list repositories of other users" do
    sign_in_as users(:juca)

    get repositories_path

    assert_response :success
    assert_no_match repositories(:tilt).url, response.body
  end

  test "new renders the form" do
    get new_repository_path
    assert_response :success
    assert_select "form[action=?]", repositories_path
  end

  test "show renders an own repository" do
    get repository_path(repositories(:tilt))
    assert_response :success
    assert_match repositories(:tilt).url, response.body
  end

  test "show does not find repositories of other users" do
    sign_in_as users(:juca)
    get repository_path(repositories(:tilt))
    assert_response :not_found
  end

  test "create builds the repository for the current user and redirects to it" do
    name = "new-#{SecureRandom.hex(4)}"

    assert_difference -> { @owner.repositories.count } do
      post repositories_path, params: { repository: { name: name } }
    end

    repository = @owner.repositories.find_by!(name: name)
    assert_redirected_to repository_path(repository)
    assert_response :see_other
    assert_equal "Repository #{name} was created.", flash[:notice]
  end

  test "create with invalid params renders the form with 422" do
    assert_no_difference -> { Repository.count } do
      post repositories_path, params: { repository: { name: "not valid!" } }
    end
    assert_response :unprocessable_content
    assert_select "#error_explanation"
  end

  test "destroy removes the repository and redirects to the list" do
    repository = @owner.repositories.create!(name: "doomed-#{SecureRandom.hex(4)}")

    assert_difference -> { Repository.count }, -1 do
      delete repository_path(repository)
    end
    assert_redirected_to repositories_path
    assert_response :see_other
    assert_equal "Repository #{repository.name} was deleted.", flash[:notice]
  end

  test "destroy does not find repositories of other users" do
    sign_in_as users(:juca)
    assert_no_difference -> { Repository.count } do
      delete repository_path(repositories(:tilt))
    end
    assert_response :not_found
  end


  test "every action requires authentication" do
    sign_out

    get repositories_path
    assert_redirected_to new_session_path
    get new_repository_path
    assert_redirected_to new_session_path
    get repository_path(repositories(:tilt))
    assert_redirected_to new_session_path

    assert_no_difference -> { Repository.count } do
      post repositories_path, params: { repository: { name: "anonymous" } }
      assert_redirected_to new_session_path
      delete repository_path(repositories(:tilt))
      assert_redirected_to new_session_path
    end
  end

  test "the root path lists the repositories" do
    get root_path

    assert_response :success
    assert_select "a[href=?]", repository_path(repositories(:tilt))
  end

  test "index only links to the pages of own repositories" do
    shared = users(:juca).repositories.create!(name: "shared-#{SecureRandom.hex(4)}")
    shared.collaborators.create!(user: @owner)

    get repositories_path

    assert_select "a[href=?]", repository_path(repositories(:tilt))
    assert_select "a[href=?]", repository_path(shared), count: 0
    assert_select "code", text: shared.url
  end

  test "show lists the collaborators and offers to remove them" do
    repository = repositories(:tilt)
    collaborator = repository.collaborators.create!(user: users(:juca))

    get repository_path(repository)

    assert_select ".collaborators .collaborator .collaborator__name", text: "juca"
    assert_select ".collaborators img.avatar[src=?]", users(:juca).gravatar_url
    assert_select ".collaborators form[action=?]", repository_collaborator_path(repository, collaborator)
    assert_select "form[action=?] input[name=?]", repository_collaborators_path(repository), "collaborator[username]"
  end

  test "show does not find a repository the user only collaborates on" do
    repositories(:tilt).collaborators.create!(user: users(:juca))
    sign_in_as users(:juca)

    get repository_path(repositories(:tilt))
    assert_response :not_found
  end

  test "create builds the git repository on the file server" do
    name = "bare-#{SecureRandom.hex(4)}"

    post repositories_path, params: { repository: { name: name } }

    assert_stored @owner.repositories.find_by!(name: name)
  end

  test "create ignores an owner given in the params" do
    name = "mine-#{SecureRandom.hex(4)}"

    post repositories_path, params: { repository: { name: name, user_id: users(:juca).id } }

    repository = Repository.find_by!(name: name)
    assert_equal @owner, repository.user
  end

  test "create with a name already used by the current user renders the form with 422" do
    assert_no_difference -> { Repository.count } do
      post repositories_path, params: { repository: { name: repositories(:tilt).name } }
    end
    assert_response :unprocessable_content
    assert_select "#error_explanation li", text: "Name has already been taken"
  end

  test "create without repository params is a bad request" do
    post repositories_path
    assert_response :bad_request
  end

  test "destroy removes the git repository from the file server" do
    repository = @owner.repositories.create!(name: "doomed-#{SecureRandom.hex(4)}")
    assert_stored repository

    delete repository_path(repository)

    assert_not_stored repository
  end

  test "destroy removes the collaborators of the repository" do
    repository = @owner.repositories.create!(name: "doomed-#{SecureRandom.hex(4)}")
    repository.collaborators.create!(user: users(:juca))

    assert_difference -> { Collaborator.count }, -1 do
      delete repository_path(repository)
    end
  end
end
