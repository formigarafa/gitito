require "spec_helper"

describe "repositories/new.html.erb" do
  before(:each) do
    assign(:repository, stub_model(Repository).as_new_record)
  end

  it "renders new repository form" do
    render

    # Run the generator again with the --webrat flag
    # if you want to use webrat matchers
    assert_select "form", action: repositories_path, method: "post" do
    end
  end
end
