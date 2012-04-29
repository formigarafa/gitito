class UserCredentialsController < InheritedResources::Base
	def begin_of_association_chain
		current_user
	end
end
