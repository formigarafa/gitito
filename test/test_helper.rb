# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

if ENV["coverage"] == "on"
  require "simplecov"
  SimpleCov.start "rails" do
    add_filter "vendor/ruby/"
    coverage_dir "../#{File.basename(ENV['CC_BUILD_ARTIFACTS'])}/coverage" if ENV["CC_BUILD_ARTIFACTS"]
  end
end

require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

module ActiveSupport
  class TestCase
    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end
