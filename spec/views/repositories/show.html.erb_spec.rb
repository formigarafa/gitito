require 'spec_helper'

describe "repositories/show.html.erb" do
  before(:each) do
    @repository = assign(:repository, stub_model(Repository))
  end

  it "renders attributes in <p>" do
    render
  end
end
