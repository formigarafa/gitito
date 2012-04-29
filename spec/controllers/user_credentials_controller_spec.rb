require 'spec_helper'

describe UserCredentialsController do

  def valid_attributes
    { :title => "test key", 
      :key => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4d8XdRasriu5HA/GrmNv6wM50TioIgjsW/NcuVnHfuF29SGZkb1mjodDkKVP7BboGIfyE1SG4mgAxv8VGtN3FBtSZPWPCD1zOGwg/uFgbugYgWRLg8IVKoSdDSgG7YwdLF7fktjpUCidFAaYCBnkzDkw+tWt9y79IdgokRwK+bmVuf80xXAr6mD9WLNqTxqXdmCHd9cMePzszdIVUtjIk0R/YHaoCZat+T2D+ICLs2oz2lv+4z5A6who82u6d0X5HDV7dIxf5s8rb/8HGbU1hshsK7VE6SXzph/dj7otkl4Mq4bJ3yLx6l7YktZ9hmVsn+S0zKcnlasD+ND2LM30X user@comment.part.com',
      :user => mock_model(User)
    }
  end

  describe "GET index" do
    it "assigns all user_credentials as @user_credentials" do
      user_credential = UserCredential.create! valid_attributes
      get :index
      assigns(:user_credentials).should eq([user_credential])
    end
  end

  describe "GET show" do
    it "assigns the requested user_credential as @user_credential" do
      user_credential = UserCredential.create! valid_attributes
      get :show, :id => user_credential.id
      assigns(:user_credential).should eq(user_credential)
    end
  end

  describe "GET new" do
    it "assigns a new user_credential as @user_credential" do
      get :new
      assigns(:user_credential).should be_a_new(UserCredential)
    end
  end

  describe "GET edit" do
    it "assigns the requested user_credential as @user_credential" do
      user_credential = UserCredential.create! valid_attributes
      get :edit, :id => user_credential.id
      assigns(:user_credential).should eq(user_credential)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new UserCredential" do
        expect {
          post :create, :user_credential => valid_attributes
        }.to change(UserCredential, :count).by(1)
      end

      it "assigns a newly created user_credential as @user_credential" do
        post :create, :user_credential => valid_attributes
        assigns(:user_credential).should be_a(UserCredential)
        assigns(:user_credential).should be_persisted
      end

      it "redirects to the created user_credential" do
        post :create, :user_credential => valid_attributes
        response.should redirect_to(UserCredential.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved user_credential as @user_credential" do
        # Trigger the behavior that occurs when invalid params are submitted
        UserCredential.any_instance.stub(:save).and_return(false)
        post :create, :user_credential => {}
        assigns(:user_credential).should be_a_new(UserCredential)
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested user_credential" do
        user_credential = UserCredential.create! valid_attributes
        # Assuming there are no other user_credentials in the database, this
        # specifies that the UserCredential created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        UserCredential.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => user_credential.id, :user_credential => {'these' => 'params'}
      end

      it "assigns the requested user_credential as @user_credential" do
        user_credential = UserCredential.create! valid_attributes
        put :update, :id => user_credential.id, :user_credential => valid_attributes
        assigns(:user_credential).should eq(user_credential)
      end

      it "redirects to the user_credential" do
        user_credential = UserCredential.create! valid_attributes
        put :update, :id => user_credential.id, :user_credential => valid_attributes
        response.should redirect_to(user_credential)
      end
    end

    describe "with invalid params" do
      it "assigns the user_credential as @user_credential" do
        user_credential = UserCredential.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        UserCredential.any_instance.stub(:save).and_return(false)
        put :update, :id => user_credential.id, :user_credential => {}
        assigns(:user_credential).should eq(user_credential)
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested user_credential" do
      user_credential = UserCredential.create! valid_attributes
      expect {
        delete :destroy, :id => user_credential.id
      }.to change(UserCredential, :count).by(-1)
    end

    it "redirects to the user_credentials list" do
      user_credential = UserCredential.create! valid_attributes
      delete :destroy, :id => user_credential.id
      response.should redirect_to(user_credentials_url)
    end
  end

end
