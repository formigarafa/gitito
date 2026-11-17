require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:juca) }

  test "visitors are asked to sign in and sent back afterwards" do
    get repositories_path
    assert_redirected_to new_session_path
    assert_equal "You need to sign in or sign up before continuing.", flash[:alert]

    post session_path, params: { email: @user.email, password: "password" }
    assert_redirected_to repositories_url
  end

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email: @user.email, password: "password" }

    assert_redirected_to root_url
    assert cookies[:session_id]
    assert_equal "Signed in successfully.", flash[:notice]
  end

  test "create ignores case and surrounding spaces in the email" do
    post session_path, params: { email: " JUCA@example.com ", password: "password" }

    assert_redirected_to root_url
  end

  test "create with invalid credentials" do
    post session_path, params: { email: @user.email, password: "wrong" }

    assert_response :unprocessable_content
    assert_nil cookies[:session_id]
    assert_select ".flash .message", text: "Invalid email or password."
  end

  test "create without credentials" do
    post session_path

    assert_response :unprocessable_content
  end

  test "create keeps the session until the browser closes by default" do
    post session_path, params: { email: @user.email, password: "password" }

    assert_no_match(/expires=/i, session_cookie_header)
  end

  test "create with remember me keeps the session for two weeks" do
    freeze_time do
      post session_path, params: { email: @user.email, password: "password", remember_me: "1" }

      assert_includes session_cookie_header, "expires=#{2.weeks.from_now.httpdate}"
    end
  end

  test "create tracks the sign in" do
    post session_path, params: { email: @user.email, password: "password" }, headers: { "REMOTE_ADDR" => "10.0.0.7" }

    @user.reload
    assert_equal 1, @user.sign_in_count
    assert_equal "10.0.0.7", @user.current_sign_in_ip
    assert_not_nil @user.current_sign_in_at
    assert_equal "10.0.0.7", @user.sessions.sole.ip_address
  end

  test "destroy" do
    sign_in_as @user

    assert_difference -> { @user.sessions.count }, -1 do
      delete session_path
    end

    assert_redirected_to new_session_path
    assert_response :see_other
    assert_empty cookies[:session_id]
  end

  private
    def session_cookie_header
      Array(response.headers["Set-Cookie"]).join("\n").lines.grep(/\Asession_id=/).sole
    end
end
