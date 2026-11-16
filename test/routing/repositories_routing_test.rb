# frozen_string_literal: true

require "test_helper"

class RepositoriesRoutingTest < ActionDispatch::IntegrationTest
  def assert_routes(method, path, action, **params)
    assert_recognizes(
      {controller: "repositories", action: action, **params},
      {path: path, method: method},
    )
  end

  test "routes to #index" do
    assert_routes :get, "/repositories", "index"
  end

  test "routes to #new" do
    assert_routes :get, "/repositories/new", "new"
  end

  test "routes to #show" do
    assert_routes :get, "/repositories/1", "show", id: "1"
  end

  test "routes to #edit" do
    assert_routes :get, "/repositories/1/edit", "edit", id: "1"
  end

  test "routes to #create" do
    assert_routes :post, "/repositories", "create"
  end

  test "routes to #update" do
    assert_routes :put, "/repositories/1", "update", id: "1"
  end

  test "routes to #destroy" do
    assert_routes :delete, "/repositories/1", "destroy", id: "1"
  end
end
