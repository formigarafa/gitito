require "spec_helper"

describe "user_credentials/show.html.erb" do
  it "displays one user credential data" do
    assign(:user_credential, stub_model(UserCredential, :title => "chave tal", :key => "trecoGrandePraDedeuComUmMonteDelEtrinasE1234Num3ros==") )

    render

    rendered.should =~ /chave tal/
    rendered.should =~ /trecoGrandePraDedeuComUmMonteDelEtrinasE1234Num3ros==/
  end
end
