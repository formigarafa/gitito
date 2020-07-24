# frozen_string_literal: true

class RepositoriesController < InheritedResources::Base
  actions :new, :create, :index, :show, :destroy

  def index
    @collaborative_repositories = current_user.collaborative_relations.map(&:repository)
    index!
  end

  private

  def begin_of_association_chain
    current_user
  end

  def permitted_params
    params.permit(repository: [:name])
  end
end
