# frozen_string_literal: true

require 'digest'
require 'open3'

module RwkvReleaseGitStaging
  class Error < StandardError; end

  GENERATED_ARTWORK_PATTERNS = [
    /\.(?:ico|png)\z/i,
    %r{\A(?:ios|macos)/Runner/Assets\.xcassets/.+/Contents\.json\z},
  ].freeze

  def self.stage!(project_root:)
    root = File.expand_path(project_root)
    existing_staged_paths = git_paths(root, 'diff', '--cached', '--name-only')
    unless existing_staged_paths.empty?
      raise Error, "release_git_index_not_empty: #{existing_staged_paths.join(', ')}"
    end

    changed_paths = git_paths(
      root,
      'ls-files',
      '--modified',
      '--deleted',
      '--others',
      '--exclude-standard',
    )
    release_paths = changed_paths.reject { |path| generated_artwork_path?(path) }
    if release_paths.empty?
      raise Error, 'release_git_no_source_changes: no non-artwork changes are available to commit'
    end

    git!(root, 'add', '--all', '--', *release_paths)
    staged_paths = git_paths(root, 'diff', '--cached', '--name-only')
    forbidden_paths = staged_paths.select { |path| generated_artwork_path?(path) }
    unless forbidden_paths.empty?
      raise Error, "release_git_artwork_staged: #{forbidden_paths.join(', ')}"
    end

    missing_paths = release_paths - staged_paths
    unless missing_paths.empty?
      raise Error, "release_git_source_not_staged: #{missing_paths.join(', ')}"
    end

    staged_paths
  end

  def self.generated_artwork_path?(path)
    GENERATED_ARTWORK_PATTERNS.any? { |pattern| pattern.match?(path) }
  end

  def self.snapshot_generated_artwork(project_root:)
    root = File.expand_path(project_root)
    git_paths(root, 'ls-files', '--modified', '--deleted').each_with_object({}) do |path, snapshot|
      next unless generated_artwork_path?(path)

      file = File.join(root, path)
      next if File.symlink?(file)

      if File.file?(file)
        snapshot[path] = Digest::SHA256.file(file).hexdigest
      elsif !File.exist?(file)
        snapshot[path] = nil # A generator may remove a tracked image before failing.
      end
    end
  end

  def self.restore_generated_artwork(project_root:, source_commit:, snapshot:)
    root = File.expand_path(project_root)
    return [] unless git!(root, 'rev-parse', 'HEAD').strip == source_commit

    tracked = git_paths(root, 'ls-files')
    paths = snapshot.filter_map do |path, digest|
      next unless tracked.include?(path) && generated_artwork_path?(path)

      file = File.join(root, path)
      next if File.symlink?(file)
      unchanged = digest.nil? ? !File.exist?(file) : File.file?(file) && Digest::SHA256.file(file).hexdigest == digest
      path if unchanged
    end
    git!(root, '--literal-pathspecs', 'restore', "--source=#{source_commit}", '--worktree', '--', *paths) unless paths.empty?
    paths
  end

  def self.git_paths(root, *arguments)
    git!(root, *arguments, '-z').split("\0").reject(&:empty?).uniq.sort
  end
  private_class_method :git_paths

  def self.git!(root, *arguments)
    stdout, stderr, status = Open3.capture3('git', '-C', root, *arguments)
    return stdout if status.success?

    message = stderr.strip
    message = stdout.strip if message.empty?
    raise Error, "release_git_command_failed: git #{arguments.join(' ')}: #{message}"
  end
  private_class_method :git!
end
