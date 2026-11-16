# frozen_string_literal: true

source "https://rubygems.org"

ruby file: ".ruby-version"

gem "devise", "~> 5.0"
gem "inherited_resources", "~> 2.1"
gem "puma"
gem "rails", "~> 8.1.0"
gem "rugged", "~> 1.9"
gem "sqlite3", ">= 2.1"

group :deployment do
  gem "capistrano", "~> 2.15", require: false
  gem "capistrano-ext", require: false
end

group :development, :test do
  gem "autotest-rails", require: false
  gem "capybara"
  gem "rake"
  gem "rspec-activemodel-mocks"
  gem "rspec-rails", "~> 8.0"
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "simplecov", require: false
  gem "ZenTest", require: false
end
