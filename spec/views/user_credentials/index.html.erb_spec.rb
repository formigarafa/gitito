require "spec_helper"

describe "user_credentials/index.html.erb" do

  context "with 2 credentials" do
    before(:each) do
      assign(:user_credentials, [
    	mock_model("UserCredential", :name => "chave um", :key => "conteudo-da-chave-um"),
    	mock_model("UserCredential", :name => "chave dois", :key => "conteudo-da-chave-dois"),
      ])
    end

    it "display both user credentials" do
      render

      rendered.should =~ /chave um/
      rendered.should =~ /conteudo-da-chave-um/

      rendered.should =~ /chave dois/
      rendered.should =~ /conteudo-da-chave-dois/
    end
  end
end
