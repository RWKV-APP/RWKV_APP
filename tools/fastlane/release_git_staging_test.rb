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

  def test_generated_artwork_restoration_leaves_a_clean_tree_for_another_run
    Dir.mktmpdir do |directory|
      initialize_repository(directory)
      write_file(directory, 'assets/branding.png', 'original')
      write_file(directory, 'macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json', '{}')
      git!(directory, 'add', '--all')
      git!(directory, 'commit', '-m', 'base')
      source_commit = git!(directory, 'rev-parse', 'HEAD').strip

      2.times do
        write_file(directory, 'assets/branding.png', 'generated')
        write_file(directory, 'macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json', '{"generated":true}')
        snapshot = RwkvReleaseGitStaging.snapshot_generated_artwork(project_root: directory)
        assert_equal 2, snapshot.size
        assert_equal 2, RwkvReleaseGitStaging.restore_generated_artwork(
          project_root: directory, source_commit: source_commit, snapshot: snapshot,
        ).size
        assert_equal '', git!(directory, 'status', '--porcelain')
      end
    end
  end

  def test_restoration_preserves_later_user_edits_source_and_untracked_files
    Dir.mktmpdir do |directory|
      initialize_repository(directory)
      write_file(directory, 'lib/existing.dart', 'source')
      write_file(directory, 'assets/[a].png', 'original literal path')
      write_file(directory, 'assets/a.png', 'original artwork')
      git!(directory, 'add', '--all')
      git!(directory, 'commit', '-m', 'base')
      source_commit = git!(directory, 'rev-parse', 'HEAD').strip

      write_file(directory, 'assets/[a].png', 'generated literal path')
      write_file(directory, 'assets/a.png', 'generated artwork')
      write_file(directory, 'lib/existing.dart', 'user source')
      write_file(directory, 'assets/untracked.png', 'untracked artwork')
      snapshot = RwkvReleaseGitStaging.snapshot_generated_artwork(project_root: directory)
      assert_equal ['assets/[a].png', 'assets/a.png'], snapshot.keys
      write_file(directory, 'assets/a.png', 'later user artwork')

      restored = RwkvReleaseGitStaging.restore_generated_artwork(
        project_root: directory, source_commit: source_commit, snapshot: snapshot,
      )

      assert_equal ['assets/[a].png'], restored
      assert_equal 'original literal path', File.binread(File.join(directory, 'assets/[a].png'))
      assert_equal 'later user artwork', File.binread(File.join(directory, 'assets/a.png'))
      assert_equal 'user source', File.binread(File.join(directory, 'lib/existing.dart'))
      assert_equal 'untracked artwork', File.binread(File.join(directory, 'assets/untracked.png'))
      assert_equal '', git!(directory, 'diff', '--cached', '--name-only')
    end
  end

  def test_partial_generator_failure_restores_modified_and_deleted_artwork
    Dir.mktmpdir do |directory|
      initialize_repository(directory)
      write_file(directory, 'assets/branding.png', 'original')
      write_file(directory, 'windows/runner/resources/app_icon.ico', 'original icon')
      git!(directory, 'add', '--all')
      git!(directory, 'commit', '-m', 'base')
      source_commit = git!(directory, 'rev-parse', 'HEAD').strip
      snapshot = {}

      assert_raises(RuntimeError) do
        begin
          begin
            write_file(directory, 'assets/branding.png', 'partial output')
            File.delete(File.join(directory, 'windows/runner/resources/app_icon.ico'))
            raise 'generator failed'
          ensure
            snapshot = RwkvReleaseGitStaging.snapshot_generated_artwork(project_root: directory)
          end
        ensure
          RwkvReleaseGitStaging.restore_generated_artwork(
            project_root: directory, source_commit: source_commit, snapshot: snapshot,
          )
        end
      end

      assert_nil snapshot.fetch('windows/runner/resources/app_icon.ico')
      assert_equal '', git!(directory, 'status', '--porcelain')
    end
  end

  def test_cleanup_does_not_restore_into_a_different_source_commit
    Dir.mktmpdir do |directory|
      initialize_repository(directory)
      write_file(directory, 'assets/branding.png', 'original')
      git!(directory, 'add', '--all')
      git!(directory, 'commit', '-m', 'base')
      source_commit = git!(directory, 'rev-parse', 'HEAD').strip
      write_file(directory, 'assets/branding.png', 'new committed artwork')
      snapshot = RwkvReleaseGitStaging.snapshot_generated_artwork(project_root: directory)
      git!(directory, 'add', '--all')
      git!(directory, 'commit', '-m', 'user commit')

      assert_empty RwkvReleaseGitStaging.restore_generated_artwork(
        project_root: directory, source_commit: source_commit, snapshot: snapshot,
      )
      assert_equal '', git!(directory, 'status', '--porcelain')
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
