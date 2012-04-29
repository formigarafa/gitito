require 'spec_helper'

describe RepositoriesController do

  def valid_attributes
    {:name => "N4m3_W1th-V4l1d.Ch4r", :user => mock_model(User)}
  end

  describe "GET index" do
    it "assigns all repositories as @repositories" do
      repository = Repository.create! valid_attributes
      get :index
      assigns(:repositories).should eq([repository])
    end
  end

  describe "GET show" do
    it "assigns the requested repository as @repository" do
      repository = Repository.create! valid_attributes
      get :show, :id => repository.id
      assigns(:repository).should eq(repository)
    end
  end

  describe "GET new" do
    it "assigns a new repository as @repository" do
      get :new
      assigns(:repository).should be_a_new(Repository)
    end
  end

  describe "GET edit" do
    it "assigns the requested repository as @repository" do
      repository = Repository.create! valid_attributes
      get :edit, :id => repository.id
      assigns(:repository).should eq(repository)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Repository" do
        expect {
          post :create, :repository => valid_attributes
        }.to change(Repository, :count).by(1)
      end

      it "assigns a newly created repository as @repository" do
        post :create, :repository => valid_attributes
        assigns(:repository).should be_a(Repository)
        assigns(:repository).should be_persisted
      end

      it "redirects to the created repository" do
        post :create, :repository => valid_attributes
        response.should redirect_to(Repository.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved repository as @repository" do
        # Trigger the behavior that occurs when invalid params are submitted
        Repository.any_instance.stub(:save).and_return(false)
        post :create, :repository => {}
        assigns(:repository).should be_a_new(Repository)
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested repository" do
        repository = Repository.create! valid_attributes
        # Assuming there are no other repositories in the database, this
        # specifies that the Repository created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Repository.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => repository.id, :repository => {'these' => 'params'}
      end

      it "assigns the requested repository as @repository" do
        repository = Repository.create! valid_attributes
        put :update, :id => repository.id, :repository => valid_attributes
        assigns(:repository).should eq(repository)
      end

      it "redirects to the repository" do
        repository = Repository.create! valid_attributes
        put :update, :id => repository.id, :repository => valid_attributes
        response.should redirect_to(repository)
      end
    end

    describe "with invalid params" do
      it "assigns the repository as @repository" do
        repository = Repository.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Repository.any_instance.stub(:save).and_return(false)
        put :update, :id => repository.id, :repository => {}
        assigns(:repository).should eq(repository)
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested repository" do
      repository = Repository.create! valid_attributes
      expect {
        delete :destroy, :id => repository.id
      }.to change(Repository, :count).by(-1)
    end

    it "redirects to the repositories list" do
      repository = Repository.create! valid_attributes
      delete :destroy, :id => repository.id
      response.should redirect_to(repositories_url)
    end
  end

end
