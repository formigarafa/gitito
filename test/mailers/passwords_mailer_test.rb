require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset links to the password reset page" do
    user = users(:juca)
    mail = PasswordsMailer.reset(user)

    assert_equal [ user.email ], mail.to
    assert_equal [ Rails.configuration.gitito[:mailer_sender] ], mail.from
    assert_equal "Reset password instructions", mail.subject

    token = mail.text_part.body.to_s[%r{/passwords/([^/\s]+)/edit}, 1]
    assert_equal user, User.find_by_password_reset_token(token)
    assert_match "expire in about 2 hours", mail.html_part.body.to_s
  end
end
