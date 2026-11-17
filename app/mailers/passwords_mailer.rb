class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "Reset password instructions", to: user.email
  end
end
