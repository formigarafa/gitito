require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  INTERNET_EXPLORER_11 = "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko".freeze
  CHROME_140 = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36".freeze

  test "modern browsers are allowed" do
    get new_session_path, headers: { "User-Agent" => CHROME_140 }
    assert_response :success
  end

  test "outdated browsers are not acceptable" do
    get new_session_path, headers: { "User-Agent" => INTERNET_EXPLORER_11 }
    assert_response :not_acceptable
  end
end
