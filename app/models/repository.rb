class Repository < ActiveRecord::Base
	validates :name, :presence => true, :format => { :with => /^[a-zA-Z0-9-_.]*$/ }
end
