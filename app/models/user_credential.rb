class UserCredential < ApplicationRecord
  belongs_to :user, optional: true
  validates :key, presence: true, uniqueness: true
  validates :user, presence: true

  after_save do
    SshFiles.sync
  end

  after_destroy do
    SshFiles.sync
  end
end
