# Where the git data of the repositories is kept: a bare git repository for
# each one, at <root>/<owner>/<name>.git.
class RepositoryStorage
  # There is something at the path already. It belongs to no repository of
  # the app, so it is neither used nor removed.
  class PathTaken < StandardError; end

  class << self
    attr_writer :default

    # The storage the app is configured to use.
    def default
      @default ||= new(root: Rails.configuration.gitito[:repositories_root])
    end
  end

  attr_reader :root

  def initialize(root:)
    @root = File.expand_path(root)
  end

  # Creates an empty git repository at +relative_path+, as in
  # "<owner>/<name>.git".
  def create(relative_path)
    path = path_of(relative_path)
    raise PathTaken, "#{path} already exists" if File.exist?(path)

    Rugged::Repository.init_at(path, :bare)
    nil
  end

  # Removes the git repository at +relative_path+, and the folder of its
  # owner when that was the last one in it.
  def remove(relative_path)
    path = path_of(relative_path)
    return unless File.directory?(path)

    FileUtils.remove_dir path
    remove_if_empty File.dirname(path)
    nil
  end

  private

  def path_of(relative_path)
    path = File.expand_path(relative_path.to_s, root)
    raise ArgumentError, "#{relative_path.inspect} is not a path inside #{root}" unless path.start_with?("#{root}/")

    path
  end

  def remove_if_empty(folder)
    Dir.rmdir folder unless folder == root
  rescue Errno::ENOTEMPTY, Errno::EEXIST
    # Other repositories live there.
  end
end
