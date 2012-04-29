require "spec_helper"

describe UserCredentialsController do
  describe "routing" do

    it "routes to #index" do
      get("/user_credentials").should route_to("user_credentials#index")
    end

    it "routes to #new" do
      get("/user_credentials/new").should route_to("user_credentials#new")
    end

    it "routes to #show" do
      get("/user_credentials/1").should route_to("user_credentials#show", :id => "1")
    end

    it "routes to #edit" do
      get("/user_credentials/1/edit").should route_to("user_credentials#edit", :id => "1")
    end

    it "routes to #create" do
      post("/user_credentials").should route_to("user_credentials#create")
    end

    it "routes to #update" do
      put("/user_credentials/1").should route_to("user_credentials#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/user_credentials/1").should route_to("user_credentials#destroy", :id => "1")
    end

  end
end
