class RegistrationsController < ApplicationController
  layout -> { authenticated? ? "application" : "authentication" }

  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: "Try again later." }

  def new
    @user = User.new
  end

  def create
    @user = User.new(params.expect(user: [ :username, :email, :password ]))

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: "Welcome! You have signed up successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @user = Current.user
  end

  # Changes need the current password; a blank new password keeps the old one.
  def update
    @user = Current.user

    if @user.update(account_params.with_defaults(password_challenge: ""))
      @user.sessions.where.not(id: Current.session).destroy_all if @user.saved_change_to_password_digest?
      redirect_to edit_registration_path, notice: "Your account has been updated successfully.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if Current.user.destroy
      cookies.delete(:session_id)
      redirect_to new_session_path, status: :see_other,
        notice: "Bye! Your account has been successfully cancelled. We hope to see you again soon."
    else
      redirect_to edit_registration_path, status: :see_other, alert: Current.user.errors.full_messages.to_sentence
    end
  end

  private
    def account_params
      params.expect(user: [ :email, :password, :password_confirmation, :password_challenge ])
    end
end
