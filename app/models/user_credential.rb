class UserCredential < ApplicationRecord
  belongs_to :user, optional: true
  validates :key, presence: true, uniqueness: true
  validates :user, presence: true

  # After the commit, so the files never get ahead of what was really saved.
  after_commit do
    SshFiles.sync
  end
end
