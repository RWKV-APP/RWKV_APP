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

        sh "cd #{project_root} && flutter pub get"
        sh "cd #{project_root} && flutter build ipa " \
           "--split-debug-info=#{sentry_symbols_path} " \
           "--dart-define=SENTRY_RELEASE=#{sentry_release} " \
           "--dart-define=SENTRY_DIST=#{build_number}"
        upload_sentry_symbols(project_root, sentry_symbols_path, sentry_release, build_number)
      end

      def self.is_supported?(platform)
        platform == :ios
      end

      def self.upload_sentry_symbols(project_root, symbols_path, sentry_release, dist)
        if ENV['SENTRY_AUTH_TOKEN'].to_s.strip.empty?
          UI.important('跳过 Sentry 符号上传 (SENTRY_AUTH_TOKEN 未设置)')
          return
        end

        sh "cd #{Shellwords.escape(project_root)} && dart run sentry_dart_plugin " \
           "#{Shellwords.escape("--sentry-define=symbols_path=#{symbols_path}")} " \
           "#{Shellwords.escape("--sentry-define=release=#{sentry_release}")} " \
           "#{Shellwords.escape("--sentry-define=dist=#{dist}")}"
      end
    end
  end
end
