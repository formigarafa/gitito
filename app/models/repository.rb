class Repository < ApplicationRecord
  belongs_to :user, optional: true
  has_many :collaborators, dependent: :destroy

  attr_readonly :name

  validates :name, presence: true, format: { with: /\A[a-zA-Z0-9\-_.]*\z/ }, uniqueness: { scope: :user_id }
  validates :user, presence: true

  def relative_path
    "#{user.username}/#{name}.git"
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
