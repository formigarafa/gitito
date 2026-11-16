source "https://rubygems.org"

ruby file: ".ruby-version"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.4", ">= 8.1.4.1"
# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 2.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Flexible authentication solution for Rails [https://github.com/heartcombo/devise]
gem "devise", "~> 5.0"
# Rails RESTful controllers with less code [https://github.com/activeadmin/inherited_resources]
gem "inherited_resources", "~> 2.1"
# Ruby bindings to libgit2, used to create bare repositories [https://github.com/libgit2/rugged]
gem "rugged", "~> 1.9"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  gem "capybara"
  # Minitest 6 ships Minitest::Mock as a separate gem
  gem "minitest-mock"
  # Code coverage reports, enabled with COVERAGE=1
  gem "simplecov", require: false
end
