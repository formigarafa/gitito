require 'spec_helper'

describe 'user_credentials/index.html.erb' do
  context 'with 2 credentials' do
    before(:each) do
      assign(:user_credentials, [
               stub_model(UserCredential, title: 'chave um', key: 'conteudo-da-chave-um'),
               stub_model(UserCredential, title: 'chave dois', key: 'conteudo-da-chave-dois')
             ])
    end

    it 'display both user credentials' do
      render

      rendered.should =~ /chave um/
      rendered.should =~ /chave dois/
    end
  end
end
