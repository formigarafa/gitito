require "test_helper"
require "open3"

# Runs a copy of script/ssh-command-proxy.sh the way sshd does, with a fake
# git-shell that prints where it was called from and what it was asked to run.
class SshCommandProxyTest < ActiveSupport::TestCase
  setup do
    @app = Dir.mktmpdir
    FileUtils.mkdir_p [ "#{@app}/script", "#{@app}/log", "#{@app}/bin", repositories_path ]
    FileUtils.cp Rails.root.join("script/ssh-command-proxy.sh"), "#{@app}/script/"
    File.write "#{@app}/bin/git-shell", "#!/bin/sh\necho \"$PWD\"\necho \"$2\"\n", perm: 0o755
    File.write "#{repositories_path}.access", "1 alice/project.git\n2 alice/project.git\n2 bob/secret.git\n"
  end

  teardown do
    FileUtils.remove_entry @app
  end

  def repositories_path
    "#{@app}/storage/repositories/production"
  end

  def proxy(credential_id, command)
    env = { "PATH" => "#{@app}/bin:#{ENV.fetch('PATH')}", "SSH_ORIGINAL_COMMAND" => command }
    stdout, stderr, status = Open3.capture3(env, "#{@app}/script/ssh-command-proxy.sh", *credential_id)
    [ stdout.lines(chomp: true), stderr, status ]
  end

  def assert_allowed(expected_command, credential_id, command)
    stdout, _stderr, status = proxy(credential_id, command)

    assert_predicate status, :success?
    assert_equal [ File.realpath(repositories_path), expected_command ], stdout
  end

  def assert_denied(credential_id, command)
    stdout, stderr, status = proxy(credential_id, command)

    assert_not status.success?, "expected #{command.inspect} to be denied"
    assert_empty stdout
    assert_match(/aborting/, stderr)
  end

  test "lets a key fetch from and push to a repository listed for it" do
    assert_allowed "git-upload-pack 'alice/project.git'", "1", "git-upload-pack 'alice/project.git'"
    assert_allowed "git-receive-pack 'alice/project.git'", "1", "git-receive-pack 'alice/project.git'"
    assert_allowed "git-upload-archive 'bob/secret.git'", "2", "git-upload-archive 'bob/secret.git'"
  end

  test "understands the other ways git writes the same request" do
    assert_allowed "git-upload-pack 'alice/project.git'", "1", "git upload-pack 'alice/project.git'"
    assert_allowed "git-upload-pack 'alice/project.git'", "1", "git-upload-pack '/alice/project.git'"
    assert_allowed "git-upload-pack 'alice/project.git'", "1", "git-upload-pack 'alice/project'"
    assert_allowed "git-upload-pack 'alice/project.git'", "1", "git-upload-pack alice/project.git"
  end

  test "denies a repository that is not listed for the key" do
    assert_denied "1", "git-upload-pack 'bob/secret.git'"
    assert_denied "1", "git-receive-pack 'bob/secret.git'"
    assert_denied "3", "git-upload-pack 'alice/project.git'"
  end

  test "denies a repository that does not exist" do
    assert_denied "1", "git-upload-pack 'alice/nothing.git'"
  end

  test "denies paths made to look like a listed repository" do
    assert_denied "1", "git-upload-pack 'alice/project.git/../../bob/secret.git'"
    assert_denied "1", "git-upload-pack 'bob/secret.git\n1 alice/project.git'"
    assert_denied "1", "git-upload-pack 'alice/project.git' 'bob/secret.git'"
    assert_denied "1", "git-upload-pack 'alice/project.git'; cat /etc/passwd"
    assert_denied "1", "git-upload-pack ''"
  end

  test "does not take part of a credential id for the whole of it" do
    File.write "#{repositories_path}.access", "12 bob/secret.git\n"

    assert_denied "1", "git-upload-pack 'bob/secret.git'"
    assert_denied "2", "git-upload-pack 'bob/secret.git'"
  end

  test "denies anything that is not a git server command" do
    assert_denied "1", "ls"
    assert_denied "1", "git-upload-pack"
    assert_denied "1", "cvs server"
  end

  test "denies when no command was received" do
    assert_denied "1", ""
  end

  test "denies a key without a credential id" do
    assert_denied [], "git-upload-pack 'alice/project.git'"
  end

  test "denies everything while there is no access file" do
    FileUtils.rm "#{repositories_path}.access"

    assert_denied "1", "git-upload-pack 'alice/project.git'"
  end

  test "logs what was allowed and what was denied" do
    proxy("1", "git-upload-pack 'alice/project.git'")
    proxy("1", "git-upload-pack 'bob/secret.git'")

    log = File.readlines("#{@app}/log/ssh-command-proxy.log", chomp: true)
    assert_equal "[credential 1] git-upload-pack alice/project.git", log.first
    assert_match(/\A\[credential 1\] DENIED .*bob\/secret\.git/, log.last)
  end

  test "accepts the access file the app writes" do
    credential = UserCredential.create!(key: "ssh-ed25519 AAAA proxy", user: users(:formigarafa))
    File.write "#{repositories_path}.access", Repository.access_lines.join("\n")

    assert_allowed "git-upload-pack 'formigarafa/tilt.git'", credential.id.to_s, "git-upload-pack 'formigarafa/tilt.git'"
    assert_denied (credential.id + 1).to_s, "git-upload-pack 'formigarafa/tilt.git'"
  end
end
