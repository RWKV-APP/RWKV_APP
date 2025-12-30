require 'fileutils'

module Fastlane
  module Actions
    class RunFlutterBuildMacosDmgAction < Action
      def self.run(params)
        project_root = File.expand_path('../..', __dir__)
        pubspec_path = File.join(project_root, 'pubspec.yaml')
        pubspec_content = File.read(pubspec_path)

        # 解析版本信息
        version_match = pubspec_content.match(/^version:\s*(.+)$/)
        version_info = version_match ? version_match[1].strip : '1.0.0+1'
        version_parts = version_info.split('+')
        version_number = version_parts[0]
        build_number = version_parts[1] || '1'

        project_name = 'rwkv_chat'
        UI.message("开始构建 macOS 版本: #{version_info}...")

        # 1. Flutter 构建
        sh "cd #{project_root} && flutter clean"
        sh "cd #{project_root} && flutter pub get"
        sh "cd #{project_root} && flutter build macos --release"

        app_folder_name = 'RWKV Chat.app'
        app_path = File.join(project_root, "build/macos/Build/Products/Release/#{app_folder_name}")

        UI.user_error!("构建失败，找不到 App: #{app_path}") unless File.exist?(app_path)

        # 2. 签名 .app 内部组件（这是公证成功的关键）
        identity_id = params[:identity_id]
        if identity_id && !identity_id.empty?
          UI.header '正在签名 .app 内容...'
          # 签名 Frameworks 和 dylib
          frameworks_path = File.join(app_path, 'Contents/Frameworks')
          if File.exist?(frameworks_path)
            Dir.glob(File.join(frameworks_path, '*.{framework,dylib}')).each do |file|
              sh("codesign --force --sign '#{identity_id}' --options runtime --timestamp --verbose '#{file}'")
            end
          end
          # 签名主程序
          sh("codesign --force --sign '#{identity_id}' --options runtime --timestamp --verbose '#{app_path}'")
        end

        # 3. 创建带引导界面的 DMG
        dmg_name = "#{project_name}_#{version_number}_#{build_number}_macos.dmg"
        dmg_path = File.join(project_root, "build/macos/#{dmg_name}")
        background_path = File.join(project_root, 'assets/dmg_bg.png')

        FileUtils.mkdir_p(File.dirname(dmg_path))
        File.delete(dmg_path) if File.exist?(dmg_path)

        UI.header '使用 create-dmg 生成视觉引导安装包...'

        if system('which create-dmg > /dev/null 2>&1')
          # 核心：配置拖拽坐标和背景
          sh("create-dmg \
            --volname 'RWKV Chat Installer' \
            --background '#{background_path}' \
            --window-pos 200 120 \
            --window-size 600 400 \
            --icon-size 100 \
            --icon '#{app_folder_name}' 160 190 \
            --hide-extension '#{app_folder_name}' \
            --app-drop-link 440 190 \
            '#{dmg_path}' \
            '#{app_path}'")
        else
          UI.important('未找到 create-dmg，改用基础 hdiutil 打包')
          sh("hdiutil create -volname 'RWKV Chat' -srcfolder '#{app_path}' -ov -format UDZO '#{dmg_path}'")
        end

        UI.success("DMG 创建成功: #{dmg_path}")
        return "./build/macos/#{dmg_name}" # 返回相对路径供 Lane 使用
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :identity_id, optional: true, type: String),
          FastlaneCore::ConfigItem.new(key: :keychain_name, optional: true, type: String),
        ]
      end

      def self.is_supported?(platform)
        platform == :mac
      end
    end
  end
end
