namespace :gitito do
  desc "Rewrite the files sshd relies on: the authorized keys and the repository access list"
  task sync_ssh_access: :environment do
    UserCredential.generate_authorized_keys_file
    Repository.generate_access_file
  end
end
