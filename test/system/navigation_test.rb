require "application_system_test_case"

class NavigationTest < ApplicationSystemTestCase
  test "visitors are sent to the login box" do
    visit root_path

    assert_current_path new_session_path
    assert_selector "h2", text: "Login Box"
    assert_field "email"
    assert_field "password"
  end

  test "a signed in user browses their repositories" do
    sign_in_as users(:formigarafa)

    visit root_path
    click_on "Repositories"

    assert_selector "h2", text: "All Repositories"
    assert_link repositories(:tilt).url

    click_on "New"

    assert_selector "h2", text: "New Repository"
    assert_field "repository[name]"
  end
end
