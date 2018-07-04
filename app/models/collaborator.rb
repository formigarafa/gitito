class Collaborator < ActiveRecord::Base
  belongs_to :user
  belongs_to :repository

  validates :user, presence: {message: "User not found"}
  validate :that_user_is_not_owner
  validates_uniqueness_of :user_id, scope: :repository_id, message: "Collaborator is already on the list"
  validates :repository, presence: {message: "Repository not found"}

  def username
    user and user.username
  end

  def that_user_is_not_owner
    errors.add :user_id, "Repository owner cannot be also a collaborator" if collaborator_owns_repository?
  end

  def collaborator_owns_repository?
    repository and repository.owned_by? user
  end
end
