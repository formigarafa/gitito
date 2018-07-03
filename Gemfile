source "http://rubygems.org"

gem "devise", "~> 1.5"
gem "inherited_resources"
gem "rails", "~> 3.0"
gem "rugged"

gem "capistrano"
gem "capistrano-ext"

group :production do
  # gem 'mysql2', '<0.3'
end

group :development, :test do
  gem "autotest-rails", "~> 4.1.0"
  gem "capybara"
  gem "rake", "< 11.0" # locked because of rspec-core
  gem "rspec-activemodel-mocks"
  gem "rspec-rails"
  gem "sqlite3"
  gem "test-unit" # rspec need that, now
  gem "web-app-theme", ">= 0.6.2"
  gem "ZenTest", "~> 4.4.2"
  # gem "metrical"
  gem "simplecov", require: false
end
