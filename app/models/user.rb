class User < ActiveRecord::Base
	validates :username, :presence => true, :format => { :with => /^[a-zA-Z0-9\-_.]*$/ }
end
