# frozen_string_literal: true

Rails.application.config.gitito =
  YAML.load_file(Rails.root.join("config/gitito.yml")).fetch("gitito").with_indifferent_access
