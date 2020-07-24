# frozen_string_literal: true

require "spec_helper"

describe CollaboratorsController do
  describe "routing" do
    it "routes to #create" do
      expect(post("/repositories/2/collaborators")).to route_to("collaborators#create", repository_id: "2")
    end

    it "routes to #destroy" do
      expect(delete("/repositories/3/collaborators/1")).to route_to(
        "collaborators#destroy",
        id: "1",
        repository_id: "3",
      )
    end
  end
end
