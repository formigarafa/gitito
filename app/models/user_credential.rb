class UserCredential < ApplicationRecord
  belongs_to :user, optional: true

  # A key is kept the way PublicKey writes it. What is not a key is kept as
  # given, to be refused by the validation.
  normalizes :key, with: ->(key) { PublicKey.parse(key)&.to_s || key }

  before_validation { self.fingerprint = public_key&.fingerprint }

  validates :key, presence: true
  validate :key_is_a_public_key_of_no_one_else, if: -> { key.present? }
  validates :user, presence: true

  # After the commit, so the files never get ahead of what was really saved.
  after_commit do
    SshFiles.sync
  end

  # The key of the credential, or nil when what it holds is not a key.
  def public_key
    PublicKey.parse(key)
  end

  private

  # The same key with another comment is still the same key: sshd would take
  # whoever comes first in the authorized keys file for both.
  def key_is_a_public_key_of_no_one_else
    if fingerprint.nil?
      errors.add :key, "is not an SSH public key"
    elsif UserCredential.where.not(id: id).exists?(fingerprint: fingerprint)
      errors.add :key, :taken
    end
  end
end
