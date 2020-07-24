# frozen_string_literal: true

class Repository < ActiveRecord::Base
  belongs_to :user
  has_many :collaborators, dependent: :destroy

  attr_readonly :name

  validates :name, presence: true, format: {with: /\A[a-zA-Z0-9\-_.]*\z/}, uniqueness: {scope: :user_id}
  validates :user, presence: true

  def self.repos_root
    "#{Rails.root}/db/users_repositories/#{Rails.env}"
  end

  def server_path
    "#{self.class.repos_root}/#{user.username}/#{name}.git"
  end

  def ssh_user
    Rails.configuration.gitito[:ssh_user]
  end

  def ssh_host
    Rails.configuration.gitito[:ssh_host]
  end

  def url
    "#{ssh_user}@#{ssh_host}:#{user.username}/#{name}.git"
  end

  def folder_exists?
    File.exist? server_path
  end

  def structure_ok?
    Rugged::Repository.new server_path
  rescue StandardError
    false
  end

  def create_structure
    bare = true
    Rugged::Repository.init_at(server_path, bare) unless folder_exists?
  end

  def remove_structure
    FileUtils.remove_dir(server_path) if File.directory? server_path
  end

  after_create do
    create_structure
  end

  after_destroy do
    remove_structure
  end

  def owned_by?(supposed_owner)
    user == supposed_owner
  end
end
