# Keys were kept as typed. From now on they are kept as PublicKey writes them,
# with a fingerprint that is the same whatever the comment, so the same key
# cannot be registered twice. That makes the index on the key of no use.
#
# Nothing is deleted: a credential that is not a key, or that repeats the key
# of an earlier one, is reported and left without fingerprint.
class AddFingerprintToUserCredentials < ActiveRecord::Migration[8.1]
  class Credential < ActiveRecord::Base
    self.table_name = "user_credentials"
  end

  def up
    add_column :user_credentials, :fingerprint, :string

    taken = Set.new
    Credential.order(:id).each do |credential|
      key = PublicKey.parse(credential.key)

      if key.nil?
        say "user credential #{credential.id} of user #{credential.user_id} is not a public key: #{credential.key.to_s.truncate(80).inspect}"
      elsif !taken.add?(key.fingerprint)
        say "user credential #{credential.id} of user #{credential.user_id} repeats the key of an earlier one"
      else
        credential.update_columns(key: key.to_s, fingerprint: key.fingerprint)
      end
    end

    add_index :user_credentials, :fingerprint, unique: true
    remove_index :user_credentials, :key, unique: true
  end

  def down
    add_index :user_credentials, :key, unique: true
    remove_column :user_credentials, :fingerprint
  end
end
