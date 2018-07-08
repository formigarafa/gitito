class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :authenticate_user!

  # Setup accessible (or protected) attributes for your model
  # attr_accessible :username, :email, :password, :password_confirmation, :remember_me
end
