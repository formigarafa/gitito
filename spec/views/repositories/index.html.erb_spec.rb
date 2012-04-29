require 'spec_helper'

describe "repositories/index.html.erb" do
  before(:each) do
    assign(:repositories, [
      stub_model(Repository),
      stub_model(Repository)
    ])
  end

  it "renders a list of repositories" do
    render
  end
end
