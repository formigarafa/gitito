require "spec_helper"

describe "user_credentials/index.html.erb" do
  context "with 2 credentials" do
    before do
      assign(:user_credentials, [
        stub_model(UserCredential, title: "key one", key: "contents-key-one"),
        stub_model(UserCredential, title: "key two", key: "contents-key-two"),
      ],)
    end

    it "display both user credentials" do
      render

      rendered.should =~ /key one/
      rendered.should =~ /key two/
    end
  end
end
