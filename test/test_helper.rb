ENV["RAILS_ENV"] ||= "test"

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start "rails"
end

require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require "minitest/mock"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Each test process syncs the files sshd relies on into a folder of its
    # own, so tests read what they wrote and not what another process did.
    def self.ssh_files_of(worker)
      folder = Rails.root.join("tmp/test/ssh_files/#{worker}")
      SshFiles.new(authorized_keys: "#{folder}/authorized_keys", proxy_config: "#{folder}/ssh-command-proxy.conf")
    end

    SshFiles.default = ssh_files_of(0)
    parallelize_setup { |worker| SshFiles.default = ssh_files_of(worker) }

    # Each test keeps its repositories in a folder of its own, which goes
    # away with the test.
    setup do
      @repositories_root = Dir.mktmpdir("gitito-repositories")
      RepositoryStorage.default = RepositoryStorage.new(root: @repositories_root)
    end

    teardown do
      FileUtils.remove_entry @repositories_root
    end

    # A public key of no one else, the way ssh-keygen prints it.
    def ssh_key(comment = nil)
      blob = [ 11, "ssh-ed25519", 32, SecureRandom.random_bytes(32) ].pack("Na*Na*")
      [ "ssh-ed25519", [ blob ].pack("m0"), comment ].compact.join(" ")
    end

    # Where the git data of +repository+ is expected to be.
    def storage_path_of(repository)
      File.join(RepositoryStorage.default.root, repository.relative_path)
    end

    def assert_stored(repository)
      assert_predicate Rugged::Repository.new(storage_path_of(repository)), :bare?
    end

    def assert_not_stored(repository)
      assert_not File.exist?(storage_path_of(repository)), "expected nothing at #{storage_path_of(repository)}"
    end
  end
end
