require "test_helper"

class RepositoryAccessTest < ActiveSupport::TestCase
  # Keeps the access file and the repositories of the block in a temporary folder.
  def with_access_file
    Dir.mktmpdir do |tmp_dir|
      Repository.stub(:access_file_path, "#{tmp_dir}/access") do
        Repository.stub(:repos_root, "#{tmp_dir}/repositories") { yield "#{tmp_dir}/access" }
      end
    end
  end

  def add_key(user)
    user.user_credentials.create!(key: "ssh-ed25519 AAAA#{SecureRandom.hex} #{user.username}")
  end

  def access_file_lines(path)
    File.readlines(path, chomp: true).sort
  end

  test "has the path of a repository inside the repositories root" do
    assert_equal "formigarafa/tilt.git", repositories(:tilt).relative_path
  end

  test "keeps the access file beside the repositories" do
    assert_equal Rails.root.join("storage/repositories/#{Rails.env}.access").to_s, Repository.access_file_path
  end

  test "lists the repositories of an owner for each of their keys" do
    with_access_file do
      keys = [ add_key(users(:formigarafa)), add_key(users(:formigarafa)) ]

      expected = keys.flat_map { |key| [ "#{key.id} formigarafa/tilt.git", "#{key.id} formigarafa/rails.git" ] }
      assert_equal expected.sort, Repository.access_lines.sort
    end
  end

  test "lists a repository for the keys of its collaborators" do
    with_access_file do
      key = add_key(users(:juca))
      repositories(:tilt).collaborators.create!(user: users(:juca))

      assert_equal [ "#{key.id} formigarafa/tilt.git" ], Repository.access_lines
    end
  end

  test "lists nothing for the keys of other users" do
    with_access_file do
      add_key(users(:drica))

      assert_empty Repository.access_lines
    end
  end

  test "writes one line for each key and repository" do
    with_access_file do |access_file|
      key = add_key(users(:formigarafa))

      assert_equal [ "#{key.id} formigarafa/rails.git", "#{key.id} formigarafa/tilt.git" ], access_file_lines(access_file)
      assert_equal "644", File.stat(access_file).mode.to_s(8)[-3..]
      assert_equal [ "access" ], Dir.children(File.dirname(access_file))
    end
  end

  test "a key being destroyed loses its access" do
    with_access_file do |access_file|
      add_key(users(:formigarafa)).destroy!

      assert_empty access_file_lines(access_file)
    end
  end

  test "a collaborator being added and removed changes the access file" do
    with_access_file do |access_file|
      key = add_key(users(:juca))

      collaborator = repositories(:tilt).collaborators.create!(user: users(:juca))
      assert_equal [ "#{key.id} formigarafa/tilt.git" ], access_file_lines(access_file)

      collaborator.destroy!
      assert_empty access_file_lines(access_file)
    end
  end

  test "a repository being created and destroyed changes the access file" do
    with_access_file do |access_file|
      key = add_key(users(:juca))

      repository = Repository.create!(name: "fresh", user: users(:juca))
      assert_equal [ "#{key.id} juca/fresh.git" ], access_file_lines(access_file)

      repository.destroy!
      assert_empty access_file_lines(access_file)
    end
  end

  test "a user being destroyed loses their access" do
    with_access_file do |access_file|
      add_key(users(:juca))
      repositories(:tilt).collaborators.create!(user: users(:juca))

      users(:juca).destroy!

      assert_empty access_file_lines(access_file)
    end
  end
end
