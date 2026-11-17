class Repository < ApplicationRecord
  belongs_to :user, optional: true
  has_many :collaborators, dependent: :destroy

  attr_readonly :name

  validates :name, presence: true, format: { with: /\A[a-zA-Z0-9\-_.]*\z/ }, uniqueness: { scope: :user_id }
  validates :user, presence: true

  def self.repos_root
    Rails.root.join("storage/repositories", Rails.env).to_s
  end

  # File script/ssh-command-proxy.sh reads to decide which repositories an SSH
  # key can reach.
  def self.access_file_path
    Rails.root.join("storage/repositories", "#{Rails.env}.access").to_s
  end

  # One "<user credential id> <owner>/<name>.git" line for each repository
  # each key can reach: the keys of its owner and of its collaborators.
  def self.access_lines
    includes(user: :user_credentials, collaborators: { user: :user_credentials }).flat_map do |repository|
      users = [ repository.user, *repository.collaborators.map(&:user) ].compact
      users.flat_map(&:user_credentials).map { |credential| "#{credential.id} #{repository.relative_path}" }
    end
  end

  # Written aside and renamed, so sshd never reads a half written file.
  def self.generate_access_file
    FileUtils.mkdir_p File.dirname(access_file_path)
    temporary_path = "#{access_file_path}.#{Process.pid}.tmp"
    File.write temporary_path, access_lines.map { |line| "#{line}\n" }.join, perm: 0o644
    File.rename temporary_path, access_file_path
  end

  def relative_path
    "#{user.username}/#{name}.git"
  end

  def server_path
    "#{self.class.repos_root}/#{relative_path}"
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
    Repository.generate_access_file
  end

  after_destroy do
    remove_structure
    Repository.generate_access_file
  end

  def owned_by?(supposed_owner)
    user == supposed_owner
  end
end
