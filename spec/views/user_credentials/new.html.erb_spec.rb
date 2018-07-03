require 'spec_helper'

describe 'user_credentials/new.html.erb' do
  before(:each) do
    assign(:user_credential, stub_model(UserCredential).as_new_record)
  end

  it 'renders new user_credential form' do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select 'form', action: user_credentials_path, method: 'post' do
    end
  end
end
