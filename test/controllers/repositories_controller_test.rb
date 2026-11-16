require "test_helper"

class RepositoriesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = users(:formigarafa)
    sign_in @owner
  end

  test "index lists own and collaborative repositories" do
    shared = users(:juca).repositories.create!(name: "shared-#{SecureRandom.hex(4)}")
    shared.collaborators.create!(user: @owner)

    get repositories_path

    assert_response :success
    assert_match repositories(:tilt).url, response.body
    assert_match shared.url, response.body
  ensure
    shared&.destroy
  end

  test "index does not list repositories of other users" do
    sign_in users(:juca)

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
    sign_in users(:juca)
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
    assert_equal "Repository was successfully created.", flash[:notice]
  ensure
    repository&.destroy
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
    assert_equal "Repository was successfully destroyed.", flash[:notice]
  end

  test "destroy does not find repositories of other users" do
    sign_in users(:juca)
    assert_no_difference -> { Repository.count } do
      delete repository_path(repositories(:tilt))
    end
    assert_response :not_found
  end
end
