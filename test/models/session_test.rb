require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "belongs to a user" do
    session = users(:juca).sessions.create!(ip_address: "10.0.0.1", user_agent: "Minitest")

    assert_equal users(:juca), session.reload.user
    assert_equal "10.0.0.1", session.ip_address
    assert_equal "Minitest", session.user_agent
  end

  test "fails with no user" do
    session = Session.new
    assert_not session.valid?
    assert_includes session.errors[:user], "must exist"
  end
end
