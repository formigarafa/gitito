# frozen_string_literal: true

require "spec_helper"

describe UserCredentialsController do
  describe "routing" do
    it "routes to #index" do
      expect(get("/user_credentials")).to route_to("user_credentials#index")
    end

    it "routes to #new" do
      expect(get("/user_credentials/new")).to route_to("user_credentials#new")
    end

    it "routes to #show" do
      expect(get("/user_credentials/1")).to route_to("user_credentials#show", id: "1")
    end

    it "routes to #edit" do
      expect(get("/user_credentials/1/edit")).to route_to("user_credentials#edit", id: "1")
    end

    it "routes to #create" do
      expect(post("/user_credentials")).to route_to("user_credentials#create")
    end

    it "routes to #update" do
      expect(put("/user_credentials/1")).to route_to("user_credentials#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete("/user_credentials/1")).to route_to("user_credentials#destroy", id: "1")
    end
  end
end
