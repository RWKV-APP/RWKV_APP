require 'shellwords'

module Fastlane
  module Actions
    class RunFlutterBuildApkAction < Action
      def self.run(params)
        # 读取 pubspec.yaml 获取项目信息
        # 使用更可靠的路径，从 fastlane 目录向上两级到项目根目录
        project_root = File.expand_path('../..', __dir__)
        pubspec_path = File.join(project_root, 'pubspec.yaml')

        pubspec_content = File.read(pubspec_path)
        name_match = pubspec_content.match(/^name:\s*(.+)$/)
        version_match = pubspec_content.match(/^version:\s*(.+)$/)

        project_name = 'rwkv_chat'
        version_info = version_match ? version_match[1].strip : '2.0.0+500'

        # 解析版本号和构建号
        version_parts = version_info.split('+')
        version_number = version_parts[0]
        build_number = version_parts[1] || '1'
        sentry_release = "rwkv-chat@#{version_number}+#{build_number}"
        sentry_symbols_path = 'build/sentry-symbols/android-arm64'

        # 构建自定义文件名
        custom_apk_name = "#{project_name}_#{version_number}_#{build_number}.apk"
        default_apk_path = File.join(project_root, 'build/app/outputs/flutter-apk/app-release.apk')
        custom_apk_path = File.join(project_root, "build/app/outputs/flutter-apk/#{custom_apk_name}")

        # 执行构建命令
        sh "cd #{project_root}; flutter clean"
        sh "cd #{project_root}; flutter pub get"
        sh "cd #{project_root}; flutter build apk --release --target-platform android-arm64 " \
           "--split-debug-info=#{sentry_symbols_path} " \
           "--dart-define=SENTRY_RELEASE=#{sentry_release} " \
           "--dart-define=SENTRY_DIST=#{build_number}"
        upload_sentry_symbols(project_root, sentry_symbols_path, sentry_release, build_number)

        # 重命名 APK 文件
        if File.exist?(default_apk_path)
          File.rename(default_apk_path, custom_apk_path)
          UI.message("APK built successfully: #{custom_apk_name}")
          UI.message("Output path: #{custom_apk_path}")

          # Return the relative path for use in the lane
          return "./build/app/outputs/flutter-apk/#{custom_apk_name}"
        else
          UI.user_error!("APK build failed: #{default_apk_path} not found")
        end
      end

      def self.is_supported?(platform)
        platform == :android
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
