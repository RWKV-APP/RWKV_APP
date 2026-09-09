require 'fileutils'
require 'shellwords'

module Fastlane
  module Actions
    class RunFlutterBuildIpaAction < Action
      def self.run(params)
        project_root = File.expand_path('../..', __dir__)
        pubspec_content = File.read(File.join(project_root, 'pubspec.yaml'))
        version_match = pubspec_content.match(/^version:\s*(.+)$/)
        version_info = version_match ? version_match[1].strip : '1.0.0+1'
        version_parts = version_info.split('+')
        version_number = version_parts[0]
        build_number = version_parts[1] || '1'
        sentry_release = "rwkv-chat@#{version_number}+#{build_number}"
        sentry_symbols_path = 'build/sentry-symbols/ios'

        Dir.chdir(project_root) do
          sh('flutter', 'clean') if params[:frozen_release]
          sh(*(['flutter', 'pub', 'get'] + (params[:frozen_release] ? ['--enforce-lockfile'] : [])))
          sh('python3', 'scripts/release_identity.py', '--verify-apple-build-inputs', '--platform', 'ios') if params[:frozen_release]
        end
        sh "cd #{Shellwords.escape(project_root)} && flutter build ipa --no-pub " \
           "--split-debug-info=#{sentry_symbols_path} " \
           "--dart-define=SENTRY_RELEASE=#{sentry_release} " \
           "--dart-define=SENTRY_DIST=#{build_number}"
        if params[:frozen_release]
          sh('python3', File.join(project_root, 'scripts/release_identity.py'), '--verify-apple-build-inputs', '--platform', 'ios', '--require-pods')
        end
        upload_sentry_symbols(project_root, sentry_symbols_path, sentry_release, build_number)
      end

      def self.available_options
        [FastlaneCore::ConfigItem.new(key: :frozen_release, optional: true, type: Boolean, default_value: false)]
      end

      def self.is_supported?(platform)
        platform == :ios
      end

      def self.upload_sentry_symbols(project_root, symbols_path, sentry_release, dist)
        if ENV['SENTRY_AUTH_TOKEN'].to_s.strip.empty?
          UI.important('跳过 Sentry 符号上传 (SENTRY_AUTH_TOKEN 未设置)')
          return
        end

        without_local_sentry_properties(project_root) do
          sh "cd #{Shellwords.escape(project_root)} && dart run sentry_dart_plugin " \
             "#{Shellwords.escape('--sentry-define=org=ce-wang')} " \
             "#{Shellwords.escape('--sentry-define=project=rwkv_app')} " \
             "#{Shellwords.escape("--sentry-define=symbols_path=#{symbols_path}")} " \
             "#{Shellwords.escape("--sentry-define=release=#{sentry_release}")} " \
             "#{Shellwords.escape("--sentry-define=dist=#{dist}")}"
        end
      end

      def self.without_local_sentry_properties(project_root)
        properties_path = File.join(project_root, 'sentry.properties')
        backup_path = "#{properties_path}.fastlane-backup.#{$$}"
        moved = false
        if File.exist?(properties_path)
          FileUtils.mv(properties_path, backup_path)
          moved = true
        end

        yield
      ensure
        FileUtils.mv(backup_path, properties_path) if moved && File.exist?(backup_path)
      end
    end
  end
end
