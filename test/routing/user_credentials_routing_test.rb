require "test_helper"

class UserCredentialsRoutingTest < ActionDispatch::IntegrationTest
  def assert_routes(method, path, action, **params)
    assert_recognizes(
      { controller: "user_credentials", action: action, **params },
      { path: path, method: method },
    )
  end

  test "routes to #index" do
    assert_routes :get, "/user_credentials", "index"
  end

  test "routes to #new" do
    assert_routes :get, "/user_credentials/new", "new"
  end

  test "routes to #show" do
    assert_routes :get, "/user_credentials/1", "show", id: "1"
  end

  test "routes to #edit" do
    assert_routes :get, "/user_credentials/1/edit", "edit", id: "1"
  end

  test "routes to #create" do
    assert_routes :post, "/user_credentials", "create"
  end

  test "routes to #update" do
    assert_routes :put, "/user_credentials/1", "update", id: "1"
  end

  test "routes to #destroy" do
    assert_routes :delete, "/user_credentials/1", "destroy", id: "1"
  end
end
