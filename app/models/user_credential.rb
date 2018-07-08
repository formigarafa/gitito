class UserCredential < ActiveRecord::Base
  belongs_to :user
  validates :key, presence: true, uniqueness: true
  validates :user, presence: true

  def authorized_keys_line
    # command="script/ssh-command-proxy.sh" ssh-rsa <long_user_key_here>
    "command=\"#{Rails.root}/script/ssh-command-proxy.sh #{id}\" #{key}"
  end

  after_save do
    UserCredential.generate_authorized_keys_file
  end

  after_destroy do
    UserCredential.generate_authorized_keys_file
  end

  class << self
    def generate_authorized_keys_file
      destination_folder = File.dirname(authorized_keys_absolute_path)
      FileUtils.mkdir_p(destination_folder, mode: 0o700) unless File.exist? destination_folder
      authorized_keys = File.new(authorized_keys_absolute_path, "w", 0o644)
      UserCredential.all.each do |uc|
        authorized_keys.puts uc.authorized_keys_line
      end
      authorized_keys.close
    end

    def authorized_keys_absolute_path
      File.expand_path Rails.configuration.gitito[:ssh_authorized_keys_file]
    end
  end
end
