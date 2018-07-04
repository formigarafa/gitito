set :bundle_cmd do
  "/home/#{user}/.gems/bin/bundle"
end

require "bundler/capistrano"

set :default_stage, "xaa"
set :stages, %w(xaa)

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
    # só com setup
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
      filename = "#{backup_path}/mysqldump.sql.bz2"
      text = capture [
        "if [ -f #{deploy_to}/current/config/database.yml ]",
        "then cat #{deploy_to}/current/config/database.yml",
        "else cat #{shared_path}/cached-copy/config/database.yml",
        "fi",
      ].join("; ")
      yaml = YAML::load(text)

      run [
        "mysqldump",
        "-h #{yaml['production']['host']}",
        "-u #{yaml['production']['username']}",
        "-p #{yaml['production']['database']}",
        "| bzip2 -c > #{filename}",
      ].join(" ") do |ch, stream, out|
        ch.send_data "#{yaml['production']['password']}\n" if out =~ /^Enter password:/
      end
    end
  end
end

after "deploy:update_code", "data:backup"
after "deploy:setup",           "data:repositories:setup"
after "deploy:finalize_update", "data:repositories:symlink"
