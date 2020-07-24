require "spec_helper"

describe "user_credentials/edit.html.erb" do
  before do
    @user_credential = assign(:user_credential, stub_model(UserCredential))
  end

  it "renders the edit user_credential form" do
    render

    # Run the generator again with the --webrat flag
    # if you want to use webrat matchers
    assert_select "form", action: user_credentials_path(@user_credential), method: "post" do
    end
  end
end
