require "test_helper"
require "open3"
require "socket"

# Runs a copy of script/ssh-command-proxy.sh the way sshd does, asking this
# app, served on a local port, with a fake git-shell that prints where it was
# called from and what it was asked to run. For the answers the app never
# gives, the script asks a server that answers what the test tells it to.
class SshCommandProxyTest < ActiveSupport::TestCase
  Capybara.server = :puma, { Silent: true }

  def self.app_server
    @app_server ||= Capybara::Server.new(Rails.application, host: "127.0.0.1").boot
  end

  setup do
    @app = Dir.mktmpdir
    FileUtils.mkdir_p [ "#{@app}/script", "#{@app}/log", "#{@app}/bin", "#{@app}/storage" ]
    FileUtils.cp Rails.root.join("script/ssh-command-proxy.sh"), "#{@app}/script/"
    File.write "#{@app}/bin/git-shell", "#!/bin/sh\necho \"$PWD\"\necho \"$2\"\n", perm: 0o755

    @owner_key = users(:formigarafa).user_credentials.create!(key: "ssh-ed25519 AAAA owner")
    @other_key = users(:juca).user_credentials.create!(key: "ssh-ed25519 AAAA other")
    write_config
  end

  teardown do
    @canned_thread&.kill
    @canned_server&.close
    FileUtils.remove_entry @app
  end

  def repositories_path
    RepositoryStorage.default.root
  end

  def config_path
    "#{@app}/storage/ssh-command-proxy.production.conf"
  end

  def app_url
    server = self.class.app_server
    "http://#{server.host}:#{server.port}#{Rails.application.routes.url_helpers.internal_ssh_access_path}"
  end

  def write_config(url: app_url, token: SshAccess.token, repositories: repositories_path)
    File.write config_path, { url: url, token: token, repositories: repositories }.compact.map { |name, value| "#{name}=#{value}\n" }.join
  end

  # Makes the script ask a server that answers +status+ and +body+ to
  # everything, in place of the app.
  def answer_with(status, body = "")
    @canned_answer = "HTTP/1.1 #{status}\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}"
    @canned_server ||= TCPServer.new("127.0.0.1", 0)
    @canned_thread ||= Thread.new { serve_canned_answer }
    write_config url: "http://127.0.0.1:#{@canned_server.addr[1]}/internal/ssh_access"
  end

  def serve_canned_answer
    loop do
      client = @canned_server.accept
      length = 0
      while (line = client.gets) && line != "\r\n"
        length = line.split(": ", 2).last.to_i if line.downcase.start_with?("content-length:")
      end
      client.read(length)
      client.write @canned_answer
      client.close
    end
  end

  def proxy(credential_id, command)
    env = { "PATH" => "#{@app}/bin:#{ENV.fetch('PATH')}", "SSH_ORIGINAL_COMMAND" => command }
    stdout, stderr, status = Open3.capture3(env, "#{@app}/script/ssh-command-proxy.sh", *credential_id&.to_s)
    [ stdout.lines(chomp: true), stderr, status ]
  end

  def assert_allowed(expected_command, credential, command)
    stdout, stderr, status = proxy(credential.id, command)

    assert_predicate status, :success?, stderr
    assert_equal [ File.realpath(repositories_path), expected_command ], stdout
  end

  def assert_denied(credential_id, command, message = /aborting/)
    stdout, stderr, status = proxy(credential_id, command)

    assert_not status.success?, "expected #{command.inspect} to be denied"
    assert_empty stdout
    assert_match message, stderr
  end

  test "lets a key fetch from and push to a repository the app allows it" do
    assert_allowed "git-upload-pack 'formigarafa/tilt.git'", @owner_key, "git-upload-pack 'formigarafa/tilt.git'"
    assert_allowed "git-receive-pack 'formigarafa/tilt.git'", @owner_key, "git-receive-pack 'formigarafa/tilt.git'"
    assert_allowed "git-upload-archive 'formigarafa/rails.git'", @owner_key, "git-upload-archive 'formigarafa/rails.git'"
  end

  test "lets the key of a collaborator in" do
    repositories(:tilt).collaborators.create!(user: users(:juca))

    assert_allowed "git-receive-pack 'formigarafa/tilt.git'", @other_key, "git-receive-pack 'formigarafa/tilt.git'"
  end

  test "runs what the app made of the other ways git writes the same request" do
    assert_allowed "git-upload-pack 'formigarafa/tilt.git'", @owner_key, "git upload-pack '/formigarafa/tilt'"
    assert_allowed "git-upload-pack 'formigarafa/tilt.git'", @owner_key, "git-upload-pack formigarafa/tilt.git"
  end

  test "denies a repository the app does not allow the key, with the words of the app" do
    assert_denied @other_key.id, "git-upload-pack 'formigarafa/tilt.git'", /\ARepository not found or access denied\. aborting/
    assert_denied @owner_key.id, "git-upload-pack 'formigarafa/nothing.git'", /\ARepository not found or access denied\. aborting/
    assert_denied 0, "git-upload-pack 'formigarafa/tilt.git'", /\ARepository not found or access denied\. aborting/
  end

  test "denies what the app does not take for a git server command, with the words of the app" do
    assert_denied @owner_key.id, "ls", /\ACommand not allowed\. aborting/
    assert_denied @owner_key.id, "cvs server", /\ACommand not allowed\. aborting/
  end

  test "sends the command to the app as it came, whatever is in it" do
    assert_denied @owner_key.id, "git-upload-pack 'formigarafa/tilt.git'; cat /etc/passwd", /Repository not found/
    assert_denied @owner_key.id, "git-upload-pack 'formigarafa/tilt.git\n'", /Repository not found/
    assert_denied @other_key.id, "git-upload-pack 'formigarafa/tilt.git'&credential_id=#{@owner_key.id}", /Repository not found/
    assert_denied @other_key.id, "@#{config_path}", /Command not allowed/
  end

  test "denies without a command or without the id of a key" do
    assert_denied @owner_key.id, "", /No command received/
    assert_denied nil, "git-upload-pack 'formigarafa/tilt.git'", /Key not recognised/
  end

  test "denies when the app does not recognise the token" do
    write_config token: "wrong"

    assert_denied @owner_key.id, "git-upload-pack 'formigarafa/tilt.git'", /Access check failed \(401\)/
  end

  test "denies when the app answers anything else" do
    [ "204 No Content", "302 Found", "500 Internal Server Error" ].each do |status|
      answer_with status, "verb=git-upload-pack\nrepository=formigarafa/tilt.git\n"

      assert_denied @owner_key.id, "git-upload-pack 'formigarafa/tilt.git'", /Access check failed \(#{status[0, 3]}\)/
    end
  end

  test "denies when the app cannot be reached" do
    closed_port = TCPServer.open("127.0.0.1", 0) { |server| server.addr[1] }
    write_config url: "http://127.0.0.1:#{closed_port}/internal/ssh_access"

    assert_denied @owner_key.id, "git-upload-pack 'formigarafa/tilt.git'", /Access check failed/
  end

  test "runs the answer of the app, not the command of the client" do
    answer_with "200 OK", "verb=git-receive-pack\nrepository=formigarafa/rails.git\n"

    assert_allowed "git-receive-pack 'formigarafa/rails.git'", @owner_key, "git-upload-pack 'formigarafa/tilt.git'"
  end

  test "does not run an answer that lacks the command or the repository" do
    [ "", "verb=git-upload-pack\n", "repository=formigarafa/tilt.git\n", "status=200\n" ].each do |answer|
      answer_with "200 OK", answer

      assert_denied @owner_key.id, "git-upload-pack 'formigarafa/tilt.git'", /Access check failed \(unexpected answer\)/
    end
  end

  test "is not fooled by a status in the answer" do
    answer_with "500 Internal Server Error", "verb=git-upload-pack\nrepository=formigarafa/tilt.git\nstatus=200\n"

    assert_denied @owner_key.id, "git-upload-pack 'formigarafa/tilt.git'", /Access check failed \(500\)/
  end

  test "shows only the printable first line of what the app says" do
    answer_with "403 Forbidden", "message=Go \e[31maway\a\nmessage=and more\n"

    _stdout, stderr, _status = proxy(@owner_key.id, "git-upload-pack 'formigarafa/tilt.git'")
    assert_equal "Go [31maway. aborting...\n", stderr
  end

  test "denies when the app forbids without saying why" do
    answer_with "403 Forbidden", "<html>Blocked host</html>"

    assert_denied @owner_key.id, "git-upload-pack 'formigarafa/tilt.git'", /\AAccess denied\. aborting/
  end

  test "denies while there is no config file" do
    FileUtils.rm config_path

    assert_denied @owner_key.id, "git-upload-pack 'formigarafa/tilt.git'", /Access check not configured/
  end

  test "denies while the config file does not say where the repositories are" do
    write_config repositories: nil

    assert_denied @owner_key.id, "git-upload-pack 'formigarafa/tilt.git'", /Access check not configured/
  end

  test "keeps the token out of the arguments of curl" do
    answer = 'verb=git-upload-pack\nrepository=formigarafa/tilt.git\n\nstatus=200\n'
    File.write "#{@app}/bin/curl", "#!/bin/sh\necho \"$@\" > #{@app}/curl.args\nprintf '#{answer}'\n", perm: 0o755

    assert_allowed "git-upload-pack 'formigarafa/tilt.git'", @owner_key, "git-upload-pack 'formigarafa/tilt.git'"
    assert_not_includes File.read("#{@app}/curl.args"), SshAccess.token
  end

  test "logs what was allowed and what was denied" do
    proxy(@owner_key.id, "git-upload-pack 'formigarafa/tilt.git'")
    proxy(@other_key.id, "git-upload-pack 'formigarafa/tilt.git'")

    log = File.readlines("#{@app}/log/ssh-command-proxy.log", chomp: true)
    assert_equal "[credential #{@owner_key.id}] git-upload-pack formigarafa/tilt.git", log.first
    assert_equal "[credential #{@other_key.id}] DENIED (Repository not found or access denied): git-upload-pack 'formigarafa/tilt.git'", log.last
  end
end
