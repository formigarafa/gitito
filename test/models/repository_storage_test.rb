require "test_helper"

class RepositoryStorageTest < ActiveSupport::TestCase
  setup do
    @root = Dir.mktmpdir
    @storage = RepositoryStorage.new(root: @root)
  end

  teardown do
    FileUtils.remove_entry @root
  end

  test "keeps the repositories of the app where the configuration says" do
    RepositoryStorage.default = nil
    configured = Rails.root.join(Rails.configuration.gitito[:repositories_root]).to_s

    assert_equal Rails.root.join("storage/repositories/test").to_s, configured
    assert_equal configured, RepositoryStorage.default.root
  end

  test "creates a bare git repository at the path" do
    @storage.create("juca/project.git")

    assert_predicate Rugged::Repository.new("#{@root}/juca/project.git"), :bare?
  end

  test "does not create over what is already at the path" do
    FileUtils.mkdir_p "#{@root}/juca/project.git"
    File.write "#{@root}/juca/project.git/leftover", "kept"

    assert_raises(RepositoryStorage::PathTaken) { @storage.create("juca/project.git") }
    assert_equal [ "leftover" ], Dir.children("#{@root}/juca/project.git")
  end

  test "removes the repository and the folder of its owner when left empty" do
    @storage.create("juca/project.git")

    @storage.remove("juca/project.git")

    assert_empty Dir.children(@root)
  end

  test "removing a repository keeps the others of its owner" do
    @storage.create("juca/doomed.git")
    @storage.create("juca/kept.git")

    @storage.remove("juca/doomed.git")

    assert_equal [ "kept.git" ], Dir.children("#{@root}/juca")
    assert_predicate Rugged::Repository.new("#{@root}/juca/kept.git"), :bare?
  end

  test "removing what is not there does nothing" do
    assert_nothing_raised { @storage.remove("juca/nowhere.git") }
    assert_empty Dir.children(@root)
  end

  test "refuses paths outside the root" do
    outside = "#{File.basename(@root)}-outside"
    FileUtils.mkdir_p "#{@root}-outside/project.git"

    [ "../#{outside}/project.git", "/#{outside}/project.git", "juca/../../#{outside}/project.git", "", ".", nil ].each do |path|
      assert_raises(ArgumentError, "expected #{path.inspect} to be refused") { @storage.create(path) }
      assert_raises(ArgumentError, "expected #{path.inspect} to be refused") { @storage.remove(path) }
    end

    assert_empty Dir.children(@root)
    assert_empty Dir.children("#{@root}-outside/project.git")
  ensure
    FileUtils.rm_rf "#{@root}-outside"
  end
end
