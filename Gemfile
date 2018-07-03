source 'http://rubygems.org'

gem 'rails', '~> 3.0'
gem 'rugged'
gem "devise", "~> 1.5"
gem 'inherited_resources'

gem 'capistrano'
gem 'capistrano-ext'

group :production do
  # gem 'mysql2', '<0.3'
end

group :development, :test do
  gem 'web-app-theme', '>= 0.6.2'
  gem 'sqlite3'
  gem 'capybara'
  gem "rspec-rails"
  gem "rspec-activemodel-mocks"
  gem 'rake', '< 11.0' # locked because of rspec-core
  gem 'test-unit' # rspec need that, now
  gem "ZenTest", "~> 4.4.2"
  gem "autotest-rails", "~> 4.1.0"
  # gem "metrical"
  gem "simplecov", :require =>false
end
