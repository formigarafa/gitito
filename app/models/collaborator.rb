class Collaborator < ActiveRecord::Base
  belongs_to :user
  belongs_to :repository

  validates :user, presence: {message: "User not found"}
  validate :that_user_is_not_owner
  validates :user_id, uniqueness: {scope: :repository_id, message: "Collaborator is already on the list"}
  validates :repository, presence: {message: "Repository not found"}

  def username
    user&.username
  end

  def that_user_is_not_owner
    errors.add :user_id, "Repository owner cannot be also a collaborator" if collaborator_owns_repository?
  end

  def collaborator_owns_repository?
    repository&.owned_by?(user)
  end
end
