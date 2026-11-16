# frozen_string_literal: true

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

      expect(rendered).to match(/key one/)
      expect(rendered).to match(/key two/)
    end

    it "renders a delete button asking for confirmation for each credential" do
      render

      assert_select "form.button_to[onsubmit*=confirm]", count: 2 do
        assert_select "input[name=_method][value=delete]"
      end
    end
  end
end
