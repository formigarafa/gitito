# The settings of config/gitito.yml, read here and nowhere else. The paths
# are made absolute: a relative one is taken from the root of the app,
# whatever folder the app was started from, and ~ is the home of its user.
Rails.application.config.gitito = Rails.application.config_for(:gitito).tap do |settings|
  %i[ssh_authorized_keys_file repositories_root].each do |path|
    settings[path] = File.expand_path(settings[path], Rails.root)
  end
end
