require "test_helper"

class HealthCheckTest < ActionDispatch::IntegrationTest
  test "reports the app as up" do
    get rails_health_check_path
    assert_response :success
  end
end
