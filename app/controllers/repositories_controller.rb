class RepositoriesController < InheritedResources::Base
  actions :new, :create, :index, :show, :destroy

  def index
    @collaborative_repositories = current_user.collaborative_relations.collect(&:repository)
    index!
  end

  def begin_of_association_chain
    current_user
  end
end
