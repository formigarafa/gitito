# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# The icons are written into the pages by the icon helper, not served.
Rails.application.config.assets.excluded_paths << Rails.root.join("app/assets/icons")

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
