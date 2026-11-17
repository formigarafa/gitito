class PasswordsController < ApplicationController
  layout "authentication"

  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "Try again later." }

  def new
  end

  def create
    if user = User.find_by(email: params[:email].to_s)
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: "Password reset instructions sent (if user with that email address exists)."
  end

  def edit
  end

  def update
    if @user.update(password_params)
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "Your password has been changed successfully. Sign in to continue."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "Password reset link is invalid or has expired."
    end

    # A blank password is left out by has_secure_password, so require one here.
    def password_params
      { password: params[:password].presence, password_confirmation: params[:password_confirmation].to_s }
    end
end
