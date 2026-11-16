# frozen_string_literal: true

require "test_helper"

class CollaboratorsRoutingTest < ActionDispatch::IntegrationTest
  test "routes to #create" do
    assert_recognizes(
      {controller: "collaborators", action: "create", repository_id: "2"},
      {path: "/repositories/2/collaborators", method: :post},
    )
  end

  test "routes to #destroy" do
    assert_recognizes(
      {controller: "collaborators", action: "destroy", id: "1", repository_id: "3"},
      {path: "/repositories/3/collaborators/1", method: :delete},
    )
  end
end
