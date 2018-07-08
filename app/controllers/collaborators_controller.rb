class CollaboratorsController < InheritedResources::Base
  actions :create, :destroy
  belongs_to :repository

  before_filter :initialize_collaborator, on: :create

  def create
    create! do |success, failure|
      success.html { redirect_to @collaborator.repository }
      failure.html do
        flash[:error] = @collaborator.errors.values.join(", ")
        redirect_to @collaborator.repository
      end
    end
  end

  private

  def initialize_collaborator
    @collaborator = Repository.find(params[:repository_id]).collaborators.new(
      user: user_to_become_collaborator,
    )
  end

  def user_to_become_collaborator
    User.where(username: params[:collaborator][:username]).first
  end
end
