require "test_helper"
require "open3"
require "socket"

# Runs a copy of script/ssh-command-proxy.sh the way sshd does, with a fake
# git-shell that prints where it was called from and what it was asked to run,
# and a small HTTP server answering the access check in place of the app.
class SshCommandProxyTest < ActiveSupport::TestCase
  TOKEN = "s3cr3t-t0k3n".freeze
  ACCESS = [
    %w[1 alice/project.git],
    %w[2 alice/project.git],
    %w[2 bob/secret.git]
  ].freeze

  setup do
    @app = Dir.mktmpdir
    FileUtils.mkdir_p [ "#{@app}/script", "#{@app}/log", "#{@app}/bin", repositories_path ]
    FileUtils.cp Rails.root.join("script/ssh-command-proxy.sh"), "#{@app}/script/"
    File.write "#{@app}/bin/git-shell", "#!/bin/sh\necho \"$PWD\"\necho \"$2\"\n", perm: 0o755

    @requests = []
    @status = nil
    @server = TCPServer.new("127.0.0.1", 0)
    @server_thread = Thread.new { serve }
    write_config
  end

  teardown do
    @server_thread.kill
    @server.close
    FileUtils.remove_entry @app
  end

  def repositories_path
    "#{@app}/storage/repositories/production"
  end

  def config_path
    "#{@app}/storage/ssh-command-proxy.production.conf"
  end

  def write_config(url: "http://127.0.0.1:#{@server.addr[1]}/internal/ssh_access", token: TOKEN)
    File.write config_path, "url=#{url}\ntoken=#{token}\n"
  end

  # Answers like Internal::SshAccessController, or with @status when set.
  def serve
    loop do
      client = @server.accept
      request_line = client.gets
      headers = {}
      while (line = client.gets) && line != "\r\n"
        name, value = line.chomp.split(": ", 2)
        headers[name.downcase] = value
      end
      uri = URI(request_line.split[1])
      params = URI.decode_www_form(uri.query.to_s).to_h
      @requests << { method: request_line.split[0], path: uri.path, params: params, authorization: headers["authorization"] }

      client.write "HTTP/1.1 #{@status || status_for(params, headers)}\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
      client.close
    end
  end

  def status_for(params, headers)
    return "401 Unauthorized" unless headers["authorization"] == "Bearer #{TOKEN}"

    ACCESS.include?([ params["credential_id"], params["repository"] ]) ? "204 No Content" : "403 Forbidden"
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

  def assert_denied(credential_id, command, message = /aborting/)
    stdout, stderr, status = proxy(credential_id, command)

    assert_not status.success?, "expected #{command.inspect} to be denied"
    assert_empty stdout
    assert_match message, stderr
  end

  test "lets a key fetch from and push to a repository the app allows it" do
    assert_allowed "git-upload-pack 'alice/project.git'", "1", "git-upload-pack 'alice/project.git'"
    assert_allowed "git-receive-pack 'alice/project.git'", "1", "git-receive-pack 'alice/project.git'"
    assert_allowed "git-upload-archive 'bob/secret.git'", "2", "git-upload-archive 'bob/secret.git'"
  end

  test "asks the app with the credential, the repository and the token" do
    proxy("1", "git-upload-pack 'alice/project.git'")

    expected = {
      method: "GET",
      path: "/internal/ssh_access",
      params: { "credential_id" => "1", "repository" => "alice/project.git" },
      authorization: "Bearer #{TOKEN}"
    }
    assert_equal [ expected ], @requests
  end

  test "understands the other ways git writes the same request" do
    assert_allowed "git-upload-pack 'alice/project.git'", "1", "git upload-pack 'alice/project.git'"
    assert_allowed "git-upload-pack 'alice/project.git'", "1", "git-upload-pack '/alice/project.git'"
    assert_allowed "git-upload-pack 'alice/project.git'", "1", "git-upload-pack 'alice/project'"
    assert_allowed "git-upload-pack 'alice/project.git'", "1", "git-upload-pack alice/project.git"
  end

  test "denies a repository the app does not allow the key" do
    assert_denied "1", "git-upload-pack 'bob/secret.git'", /Repository not found or access denied/
    assert_denied "1", "git-receive-pack 'bob/secret.git'"
    assert_denied "3", "git-upload-pack 'alice/project.git'"
    assert_denied "1", "git-upload-pack 'alice/nothing.git'", /Repository not found or access denied/
  end

  test "denies paths that are not of a repository without asking the app" do
    assert_denied "1", "git-upload-pack 'alice/project.git' 'bob/secret.git'"
    assert_denied "1", "git-upload-pack 'alice/project.git'; cat /etc/passwd"
    assert_denied "1", "git-upload-pack 'alice/project.git\n'"
    assert_denied "1", "git-upload-pack 'alice/project.git&credential_id=2'"
    assert_denied "1", "git-upload-pack ''"

    assert_empty @requests
  end

  test "denies anything that is not a git server command without asking the app" do
    assert_denied "1", "ls", /Command not allowed/
    assert_denied "1", "git-upload-pack"
    assert_denied "1", "cvs server"
    assert_denied "1", "", /No command received/
    assert_denied [], "git-upload-pack 'alice/project.git'", /Key not recognised/

    assert_empty @requests
  end

  test "denies when the app does not recognise the token" do
    write_config token: "wrong"

    assert_denied "1", "git-upload-pack 'alice/project.git'", /Access check failed \(401\)/
  end

  test "denies when the app answers anything else" do
    [ "200 OK", "302 Found", "500 Internal Server Error" ].each do |status|
      @status = status

      assert_denied "1", "git-upload-pack 'alice/project.git'", /Access check failed \(#{status[0, 3]}\)/
    end
  end

  test "denies when the app cannot be reached" do
    closed_port = TCPServer.open("127.0.0.1", 0) { |server| server.addr[1] }
    write_config url: "http://127.0.0.1:#{closed_port}/internal/ssh_access"

    assert_denied "1", "git-upload-pack 'alice/project.git'", /Access check failed/
  end

  test "denies while there is no config file" do
    FileUtils.rm config_path

    assert_denied "1", "git-upload-pack 'alice/project.git'", /Access check not configured/
    assert_empty @requests
  end

  test "keeps the token out of the arguments of curl" do
    File.write "#{@app}/bin/curl", "#!/bin/sh\necho \"$@\" > #{@app}/curl.args\nprintf 204\n", perm: 0o755

    assert_allowed "git-upload-pack 'alice/project.git'", "1", "git-upload-pack 'alice/project.git'"
    assert_not_includes File.read("#{@app}/curl.args"), TOKEN
  end

  test "logs what was allowed and what was denied" do
    proxy("1", "git-upload-pack 'alice/project.git'")
    proxy("1", "git-upload-pack 'bob/secret.git'")

    log = File.readlines("#{@app}/log/ssh-command-proxy.log", chomp: true)
    assert_equal "[credential 1] git-upload-pack alice/project.git", log.first
    assert_match(/\A\[credential 1\] DENIED .*bob\/secret\.git/, log.last)
  end
end
