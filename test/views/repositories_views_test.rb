require "test_helper"

class RepositoriesViewsTest < ActionView::TestCase
  setup do
    controller.controller_path = "repositories"
  end

  test "index renders a list of repositories" do
    @repositories = [ repositories(:tilt), repositories(:rails) ]
    @collaborative_repositories = []

    render template: "repositories/index"

    @repositories.each do |repository|
      assert_select "a[href=?]", repository_path(repository), text: repository.url
    end
  end

  test "new renders new repository form" do
    @repository = Repository.new

    render template: "repositories/new"

    assert_select "form[action=?][method=?]", repositories_path, "post"
  end
end
