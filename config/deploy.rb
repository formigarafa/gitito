# frozen_string_literal: true

set :bundle_cmd do
  "/home/#{user}/.gems/bin/bundle"
end

require "bundler/capistrano"

set :default_stage, "xaa"
set :stages, %w[xaa]

require "capistrano/ext/multistage"

require "#{File.dirname(__FILE__)}/deploy/capistrano_gitito_yml.rb"
require "#{File.dirname(__FILE__)}/deploy/capistrano_database_yml.rb"

default_run_options[:pty] = true

# be sure to change these
set :user, "xaa"
set :application, "gitito"
set :deploy_to do
  "/home/#{user}/#{domain}"
end

# the rest should be good
set :repository, "gitito@fortito.com.br:repos/gitito.git"

role :app do
  domain
end

role :web do
  domain
end

role :db, primary: true do
  domain
end

set :deploy_via, :remote_cache
set :scm, "git"

set :branch do
  # default_tag = `git tag`.split("\n").last
  default_tag = "master"

  Capistrano::CLI.ui.ask(
    "Version to deploy (if is a tag make sure to push it first):",
  ) {|q| q.default = default_tag }
end

set :git_shallow_clone, 1
set :scm_verbose, true
set :use_sudo, false

namespace :deploy do
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

set :backup_path do
  "#{shared_path}/backup/#{release_name}"
end

set :users_repositories_path do
  "#{shared_path}/users_repositories"
end

namespace :data do
  namespace :repositories do
    # only to be run with setup
    task :setup, roles: :db, only: {primary: true} do
      run "mkdir -p #{users_repositories_path}"
    end

    task :symlink, except: {no_release: true} do
      run "ln -nfs #{users_repositories_path} #{release_path}/db/users_repositories"
    end
  end

  namespace :backup do
    task :default do
      database
      files
    end

    task :files, roles: :db, only: {primary: true} do
      run "mkdir -p #{backup_path}"
      run "tar cjf #{backup_path}/system.tar.bz2 #{shared_path}/system"
    end

    task :database, roles: :db, only: {primary: true} do
      run "mkdir -p #{backup_path}"
      database_file = "#{shared_path}/db/production.sqlite3"
      backup_file = "#{backup_path}/production.sqlite3"
      run "if [ -f #{database_file} ]; then " \
          "sqlite3 #{database_file} \".backup '#{backup_file}'\" && bzip2 #{backup_file}; fi"
    end
  end
end

after "deploy:update_code", "data:backup"
after "deploy:setup",           "data:repositories:setup"
after "deploy:finalize_update", "data:repositories:symlink"
