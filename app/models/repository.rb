class Repository < ApplicationRecord
  belongs_to :user, optional: true
  has_many :collaborators, dependent: :destroy

  # A repository is kept, and asked for, at <username of the owner>/<name>.git.
  # Both names are made of these characters only, so the path is always one
  # folder inside another and never points anywhere else.
  NAME_CHARACTER = /[a-zA-Z0-9\-_.]/
  NAME_FORMAT = /\A#{NAME_CHARACTER}*\z/
  RELATIVE_PATH_FORMAT = %r{\A(?<owner>#{NAME_CHARACTER}+)/(?<name>#{NAME_CHARACTER}+)\.git\z}

  attr_readonly :name

  validates :name, presence: true, format: { with: NAME_FORMAT }, uniqueness: { scope: :user_id }
  validates :user, presence: true

  # The repository at +path+, as in "<owner>/<name>.git", when there is one.
  def self.find_by_relative_path(path)
    match = RELATIVE_PATH_FORMAT.match(path.to_s)
    match && joins(:user).find_by(name: match[:name], users: { username: match[:owner] })
  end

  def relative_path
    "#{user.username}/#{name}.git"
  end

  # What git is given to clone the repository.
  def url
    settings = Rails.configuration.gitito

    "#{settings[:ssh_user]}@#{settings[:ssh_host]}:#{relative_path}"
  end

  # The git repository is created with the record, so failing to create it
  # fails the save, and goes away if the creation is rolled back. It is only
  # removed once the destruction is committed: there is no bringing it back.
  after_create :create_storage
  after_rollback :remove_storage_just_created
  after_commit :keep_storage_just_created
  after_commit :remove_storage, on: :destroy

  def owned_by?(supposed_owner)
    user == supposed_owner
  end

  # The owner and the collaborators can fetch from and push to the repository.
  def accessible_by?(supposed_user)
    owned_by?(supposed_user) || collaborators.exists?(user: supposed_user)
  end

  private

  # What is already there belongs to no repository, so it is not handed to
  # this one: the repository is not saved.
  def create_storage
    RepositoryStorage.default.create(relative_path)
    @storage_just_created = true
  rescue RepositoryStorage::PathTaken
    errors.add :name, "is taken by data left on the server"
    raise ActiveRecord::Rollback
  end

  def remove_storage_just_created
    remove_storage if @storage_just_created
    @storage_just_created = false
  end

  def keep_storage_just_created
    @storage_just_created = false
  end

  def remove_storage
    RepositoryStorage.default.remove(relative_path)
  end
end
