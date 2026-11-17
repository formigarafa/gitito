namespace :gitito do
  desc "Rewrite the files sshd relies on: the authorized keys and the config of script/ssh-command-proxy.sh"
  task sync_ssh_access: :environment do
    SshFiles.sync
  end
end
