class UserCredential < ActiveRecord::Base
  belongs_to :user
  validates :key, :presence => true, :uniqueness => true
  validates :user, :presence => true

  def authorized_keys_line
    # command="script/ssh-command-proxy.sh" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCo/i6cSmjb4qOi5T127hq+MUZsmc9XBWEcp4jIyUtr+UvgMmvYtoX5EVLaScxLeJjTH4XBfCqUssGiIb7bZDDOkJwzkwfREb4MfYd+cTq1mqFFAJyfOozBfSIyo+AZz/cWPKDYLvm6I253KTgI/oF6i7igZe4oN3lvBfOKFOMUqzdPvX6YrLl+cvLdIz0JM3bf2AqUoVHrPlirLNmcGBthmPJ8fdITj6hxUY3YryqmnEzhRvZRIYUzqH48RPS8G5uFs5kjJm4DLZOgT2v0cKF946V0xAQ3FitXdXtrgN0KIYWviooVaw3FE5hr40Cps3G0Wl99sLz76goScK3/k1vF
    "command=\"#{Rails.root}/script/ssh-command-proxy.sh #{self.id}\" #{key}"
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
      FileUtils.mkdir_p(destination_folder, :mode => 0700) unless File.exists? destination_folder
      authorized_keys = File.new(authorized_keys_absolute_path, "w", 0644)
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
