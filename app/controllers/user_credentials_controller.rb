# frozen_string_literal: true

class UserCredentialsController < InheritedResources::Base
  actions :new, :create, :index, :edit, :update, :destroy

  private

  def begin_of_association_chain
    current_user
  end

  def permitted_params
    params.permit(user_credential: %i[title key])
  end
end
