class UserCredentialsController < ApplicationController
  before_action :set_user_credential, only: %i[edit update destroy]

  def index
    @user_credentials = Current.user.user_credentials
  end

  def new
    @user_credential = Current.user.user_credentials.new
  end

  def edit
  end

  def create
    @user_credential = Current.user.user_credentials.new(user_credential_params)

    if @user_credential.save
      redirect_to user_credentials_path, notice: "User credential was successfully created.", status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @user_credential.update(user_credential_params)
      redirect_to user_credentials_path, notice: "User credential was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @user_credential.destroy
    redirect_to user_credentials_path, notice: "User credential was successfully destroyed.", status: :see_other
  end

  private

  def set_user_credential
    @user_credential = Current.user.user_credentials.find(params.expect(:id))
  end

  def user_credential_params
    params.expect(user_credential: %i[title key])
  end
end
