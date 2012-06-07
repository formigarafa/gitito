class RepositoriesController < InheritedResources::Base
	actions :new, :create, :index, :show, :destroy

	
	def begin_of_association_chain
		current_user
	end
end
