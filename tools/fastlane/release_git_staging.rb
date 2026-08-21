# frozen_string_literal: true

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
