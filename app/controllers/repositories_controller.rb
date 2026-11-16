class RepositoriesController < ApplicationController
  before_action :set_repository, only: %i[show destroy]

  def index
    @repositories = current_user.repositories
    @collaborative_repositories = current_user.collaborative_relations.map(&:repository)
  end

  def show
  end

  def new
    @repository = current_user.repositories.new
  end

  def create
    @repository = current_user.repositories.new(repository_params)

    if @repository.save
      redirect_to @repository, notice: "Repository was successfully created.", status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    @repository.destroy
    redirect_to repositories_path, notice: "Repository was successfully destroyed.", status: :see_other
  end

  private

  def set_repository
    @repository = current_user.repositories.find(params.expect(:id))
  end

  def repository_params
    params.expect(repository: [ :name ])
  end
end
