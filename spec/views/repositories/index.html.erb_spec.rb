require 'spec_helper'

describe "repositories/index.html.erb" do
  before(:each) do
    assign(:repositories, [
      stub_model(Repository, :url => 'repo1'),
      stub_model(Repository, :url => 'repo2')
    ])
  end

  it "renders a list of repositories" do
    render
  end
end
