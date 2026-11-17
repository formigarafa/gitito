require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  test "has the user of the current session" do
    Current.session = users(:juca).sessions.create!
    assert_equal users(:juca), Current.user
  end

  test "has no user without a session" do
    Current.session = nil
    assert_nil Current.user
  end
end
