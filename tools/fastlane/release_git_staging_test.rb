# frozen_string_literal: true

require 'fileutils'
require 'minitest/autorun'
require 'tmpdir'
require_relative 'release_git_staging'

class RwkvReleaseGitStagingTest < Minitest::Test
  def test_stages_tracked_and_untracked_source_without_generated_artwork
    Dir.mktmpdir do |directory|
      initialize_repository(directory)
      write_file(directory, 'lib/existing.dart', 'before')
      write_file(directory, 'assets/design/light/branding.png', 'before')
      write_file(directory, 'windows/runner/resources/app_icon.ico', 'before')
      write_file(directory, 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json', '{}')
      git!(directory, 'add', '--all')
      git!(directory, 'commit', '-m', 'base')

      write_file(directory, 'lib/existing.dart', 'after')
      write_file(directory, 'lib/new.dart', 'new source')
      write_file(directory, 'assets/design/light/branding.png', 'after')
      write_file(directory, 'assets/design/light/new-branding.png', 'new artwork')
      write_file(directory, 'windows/runner/resources/app_icon.ico', 'after')
      write_file(directory, 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json', '{"changed":true}')

      staged_paths = RwkvReleaseGitStaging.stage!(project_root: directory)

      assert_equal ['lib/existing.dart', 'lib/new.dart'], staged_paths
      assert_equal(
        [
          'assets/design/light/branding.png',
          'assets/design/light/new-branding.png',
          'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
          'windows/runner/resources/app_icon.ico',
        ],
        changed_unstaged_paths(directory),
      )
    end
  end

  def test_refuses_to_mix_an_existing_index_into_release_commit
    Dir.mktmpdir do |directory|
      initialize_repository(directory)
      write_file(directory, 'lib/existing.dart', 'before')
      git!(directory, 'add', '--all')
      git!(directory, 'commit', '-m', 'base')
      write_file(directory, 'lib/existing.dart', 'after')
      git!(directory, 'add', 'lib/existing.dart')

      error = assert_raises(RwkvReleaseGitStaging::Error) do
        RwkvReleaseGitStaging.stage!(project_root: directory)
      end

      assert_match 'release_git_index_not_empty', error.message
    end
  end

  private

  def initialize_repository(directory)
    git!(directory, 'init')
    git!(directory, 'config', 'user.email', 'release-test@example.com')
    git!(directory, 'config', 'user.name', 'Release Test')
  end

  def write_file(directory, relative_path, contents)
    path = File.join(directory, relative_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.binwrite(path, contents)
  end

  def changed_unstaged_paths(directory)
    stdout = git!(
      directory,
      'ls-files',
      '--modified',
      '--deleted',
      '--others',
      '--exclude-standard',
      '-z',
    )
    stdout.split("\0").reject(&:empty?).uniq.sort
  end

  def git!(directory, *arguments)
    stdout, stderr, status = Open3.capture3('git', '-C', directory, *arguments)
    raise "git #{arguments.join(' ')} failed: #{stderr}" unless status.success?

    stdout
  end
end
