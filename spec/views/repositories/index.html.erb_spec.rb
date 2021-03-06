# frozen_string_literal: true

require "spec_helper"

describe "repositories/index.html.erb" do
  before do
    assign(:repositories, [
      stub_model(Repository, url: "repo1"),
      stub_model(Repository, url: "repo2"),
    ],)
    assign(:collaborative_repositories, [])
  end

  it "renders a list of repositories" do
    render
  end
end
