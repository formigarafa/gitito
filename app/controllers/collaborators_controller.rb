class CollaboratorsController < InheritedResources::Base
  actions :create, :destroy
  belongs_to :repository

  def create
    user = User.where(username: params[:collaborator][:username]).find(:first)
    @collaborator = Repository.find(params[:repository_id]).collaborators.new user: user
    create! do |success, failure|
      success.html do
        redirect_to repository_url(@collaborator.repository)
      end
      failure.html do
        flash[:error] = @collaborator.errors.values.join(", ")
        redirect_to repository_url(@collaborator.repository)
      end
    end
  end
end
