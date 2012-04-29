class UserCredentialsController < InheritedResources::Base
	actions :new, :create, :index, :edit, :update, :destroy

	def begin_of_association_chain
		current_user
	end
end
