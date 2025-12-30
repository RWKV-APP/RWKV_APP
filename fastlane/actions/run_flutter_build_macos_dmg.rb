require 'fileutils'

module Fastlane
  module Actions
    class RunFlutterBuildMacosDmgAction < Action
      def self.run(params)
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

        UI.message("Building macOS app for version #{version_info}...")

        # 执行构建命令
        sh "cd #{project_root}; flutter clean"
        sh "cd #{project_root}; flutter pub get"
        sh "cd #{project_root}; flutter build macos --release"

        # 构建后的 app 路径
        app_path = File.join(project_root, 'build/macos/Build/Products/Release/RWKV Chat.app')
        
        unless File.exist?(app_path)
          UI.user_error!("macOS app build failed: #{app_path} not found")
        end

        UI.message("macOS app built successfully: #{app_path}")

        # 签名应用（证书和钥匙串已在 lane 中管理）
        identity_id = params[:identity_id]
        keychain_name = params[:keychain_name]

        if identity_id && !identity_id.empty?
          UI.message("Signing macOS app with identity: #{identity_id}...")
          
          begin
            # 递归签名所有嵌套的框架和插件（不使用 --deep，手动签名更可靠）
            frameworks_path = File.join(app_path, 'Contents/Frameworks')
            if File.exist?(frameworks_path)
              UI.message("Signing nested frameworks...")
              Dir.glob(File.join(frameworks_path, '*.framework')).each do |framework|
                UI.message("  Signing: #{File.basename(framework)}")
                sh("codesign --force --sign '#{identity_id}' --options runtime --timestamp --verbose '#{framework}'")
              end
              
              # 签名插件
              Dir.glob(File.join(frameworks_path, '*.dylib')).each do |dylib|
                UI.message("  Signing: #{File.basename(dylib)}")
                sh("codesign --force --sign '#{identity_id}' --options runtime --timestamp --verbose '#{dylib}'")
              end
            end
            
            # 签名主应用（不使用 --deep，因为所有嵌套组件已经手动签名）
            UI.message("Signing main application...")
            sh("codesign --force --sign '#{identity_id}' --options runtime --timestamp --verbose '#{app_path}'")
            
            # 验证签名
            UI.message("Verifying signature...")
            sh("codesign --verify --verbose --strict '#{app_path}'")
            
            # 检查签名详情
            sh("codesign -dv --verbose=4 '#{app_path}'")
            
            UI.success("macOS app signed successfully")
          rescue => e
            UI.user_error!("Failed to sign macOS app: #{e.message}")
          end
        else
          UI.message("No signing identity provided, skipping signing")
        end

        # 创建 DMG
        dmg_name = "#{project_name}_#{version_number}_#{build_number}_macos-universal.dmg"
        dmg_path = File.join(project_root, "build/macos/#{dmg_name}")
        
        UI.message("Creating DMG: #{dmg_name}...")
        
        # 确保 build/macos 目录存在
        FileUtils.mkdir_p(File.dirname(dmg_path))
        
        # 使用 create-dmg 或 hdiutil 创建 DMG
        # 检查是否有 create-dmg
        if system("which create-dmg > /dev/null 2>&1")
          sh("create-dmg --volname '#{project_name}' --window-pos 200 120 --window-size 800 400 --icon-size 100 --app-drop-link 600 185 '#{dmg_path}' '#{app_path}'")
        else
          # 使用 hdiutil 创建简单的 DMG
          UI.message("Using hdiutil to create DMG...")
          sh("hdiutil create -volname '#{project_name}' -srcfolder '#{app_path}' -ov -format UDZO '#{dmg_path}'")
        end

        unless File.exist?(dmg_path)
          UI.user_error!("DMG creation failed: #{dmg_path} not found")
        end

        UI.success("DMG created successfully: #{dmg_name}")
        UI.message("Output path: #{dmg_path}")

        # Return the relative path for use in the lane
        return "./build/macos/#{dmg_name}"
      end

      def self.is_supported?(platform)
        platform == :mac
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :identity_id,
                                       env_name: "MACOS_IDENTITY_ID",
                                       description: "Signing identity ID (e.g., 'Developer ID Application: Your Name (TEAM_ID)')",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :keychain_name,
                                       description: "Keychain name where certificate is stored (for reference only, managed by lane)",
                                       optional: true,
                                       type: String),
        ]
      end
    end
  end
end


