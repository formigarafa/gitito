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

  after_create :create_storage

  after_destroy do
    RepositoryStorage.default.remove(relative_path)
  end

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
  rescue RepositoryStorage::PathTaken
    errors.add :name, "is taken by data left on the server"
    raise ActiveRecord::Rollback
  end
end
