require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Signs in through the login box; fixture users all have "password".
  def sign_in_as(user, password: "password")
    visit new_session_path
    fill_in "email", with: user.email
    fill_in "password", with: password
    click_on "Sign in"
    assert_text "Signed in successfully."
  end

  # Does what opens the confirmation dialog, in the block, checks what the
  # dialog asks and answers it with its button named +with+.
  def confirm_dialog(message, with: "Confirm")
    yield

    within "dialog[open]" do
      assert_text message
      click_on with
    end
  end
end
