class SessionsController < ApplicationController
  layout "authentication"

  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(email: params[:email].to_s, password: params[:password].to_s)
      start_new_session_for user, remember: params[:remember_me] == "1"
      redirect_to after_authentication_url, notice: "Signed in successfully."
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, notice: "Signed out successfully.", status: :see_other
  end
end
