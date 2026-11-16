require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Gitito
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Devise responds through the responders gem, which keeps 200 and 302 for
    # compatibility. Hotwire/Turbo needs failed form submissions to
    # render with 422 and redirects after non-GET requests to use 303.
    config.responders.error_status = :unprocessable_content
    config.responders.redirect_status = :see_other

    config.to_prepare do
      Devise::SessionsController.layout "devise"
      Devise::RegistrationsController.layout(proc { |_controller| user_signed_in? ? "application" : "devise" })
      Devise::ConfirmationsController.layout "devise"
      Devise::UnlocksController.layout "devise"
      Devise::PasswordsController.layout "devise"
      ActionMailer::Base.default_url_options = { host: Rails.configuration.gitito[:web_host] }
    end
  end
end
