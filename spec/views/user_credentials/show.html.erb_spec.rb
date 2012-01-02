require "spec_helper"

describe "user_credentials/show.html.erb" do
  it "displays one user credential data" do
    assign(:user_credential, mock_model("UserCredential", :name => "chave tal", :key => "trecoGrandePraDedeuComUmMonteDelEtrinasE1234Num3ros==") )

    render

    rendered.should =~ /chave tal/
    rendered.should =~ /trecoGrandePraDedeuComUmMonteDelEtrinasE1234Num3ros==/
  end
end
