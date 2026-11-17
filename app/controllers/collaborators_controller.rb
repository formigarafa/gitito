class CollaboratorsController < ApplicationController
  before_action :set_repository

  def create
    @collaborator = @repository.collaborators.new(user: user_to_become_collaborator)

    if @collaborator.save
      flash[:notice] = "Collaborator was successfully created."
    else
      flash[:error] = @collaborator.errors.map(&:message).join(", ")
    end
    redirect_to @repository
  end

  def destroy
    @repository.collaborators.find(params.expect(:id)).destroy
    redirect_to @repository, notice: "Collaborator was successfully destroyed.", status: :see_other
  end

  private

  def set_repository
    @repository = Current.user.repositories.find(params.expect(:repository_id))
  end

  def user_to_become_collaborator
    User.find_by(username: params.expect(collaborator: [ :username ])[:username])
  end
end
