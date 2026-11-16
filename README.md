# Gitito [![Build Status](https://travis-ci.org/formigarafa/gitito.svg?branch=master)](https://travis-ci.org/formigarafa/gitito)
Private git repository management. With minimum server requirements.
_(eg.: Works with Dreamhost shared servers)_

# Description
Works similar github and gitorious, you register ssh public keys on it, create repositories
you can clone, push and pull from these repositories. 
You can also add collaborators who will have access to the repositories.

# Known Issues:
Other users can access everyone's repositories if they know repos addresses.
This security check is not done, yet.

# Requirements:

Ruby 4.0.9 (see `.ruby-version`), Rails 8.1, SQLite 3 (used in every environment, including production).

In production set `SECRET_KEY_BASE` (or use Rails credentials).

# Configuration
create files config/gitito.yml and config/database.yml 
  _Hint: use config/gitito.yml.example and config/database.yml.example as model to create these files_

# Install

$ gem install bundler
$ bundle install
$ bin/rails db:setup
