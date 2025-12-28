require 'securerandom'
require 'base64'
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
        app_path = File.join(project_root, 'build/macos/Build/Products/Release/Runner.app')
        
        unless File.exist?(app_path)
          UI.user_error!("macOS app build failed: #{app_path} not found")
        end

        UI.message("macOS app built successfully: #{app_path}")

        # 签名应用
        certificate_path = params[:certificate_path]
        certificate_base64 = params[:certificate_base64]
        certificate_password = params[:certificate_password]
        identity_id = params[:identity_id]

        # 处理证书：优先使用文件路径，如果没有则从 base64 解码
        temp_cert_path = nil
        if certificate_path && File.exist?(certificate_path)
          temp_cert_path = certificate_path
        elsif certificate_base64 && !certificate_base64.empty?
          # 从 base64 解码证书
          temp_cert_path = File.join(project_root, "build/macos/temp_cert_#{Time.now.to_i}.p12")
          cert_data = Base64.decode64(certificate_base64)
          File.binwrite(temp_cert_path, cert_data)
          UI.message("Decoded certificate from base64")
        end

        if temp_cert_path && File.exist?(temp_cert_path)
          UI.message("Signing macOS app with certificate...")
          
          # 导入证书到 keychain
          keychain_name = "fastlane_macos_#{Time.now.to_i}"
          keychain_password = SecureRandom.hex(16)
          
          begin
            # 创建临时 keychain
            sh("security create-keychain -p '#{keychain_password}' #{keychain_name}")
            sh("security set-keychain-settings -t 3600 -u #{keychain_name}")
            sh("security unlock-keychain -p '#{keychain_password}' #{keychain_name}")
            sh("security default-keychain -s #{keychain_name}")
            
            # 导入证书
            sh("security import '#{temp_cert_path}' -k #{keychain_name} -P '#{certificate_password}' -T /usr/bin/codesign -T /usr/bin/security")
            
            # 查找证书身份
            identity = identity_id || `security find-identity -v -p codesigning #{keychain_name} | grep -o '"[^"]*"' | head -1 | tr -d '"'`.strip
            
            if identity.empty?
              UI.user_error!("Failed to find signing identity in certificate")
            end
            
            UI.message("Signing with identity: #{identity}")
            
            # 签名应用
            sh("codesign --force --deep --sign '#{identity}' '#{app_path}'")
            
            # 验证签名
            sh("codesign --verify --verbose '#{app_path}'")
            UI.success("macOS app signed successfully")
            
          ensure
            # 清理 keychain
            sh("security delete-keychain #{keychain_name}") rescue nil
            # 清理临时证书文件
            File.delete(temp_cert_path) if temp_cert_path && temp_cert_path.include?('temp_cert') && File.exist?(temp_cert_path)
          end
        else
          UI.message("No certificate provided, skipping signing")
        end

        # 创建 DMG
        dmg_name = "#{project_name}_#{version_number}_#{build_number}_macos.dmg"
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
          FastlaneCore::ConfigItem.new(key: :certificate_path,
                                       env_name: "MACOS_CERTIFICATE_PATH",
                                       description: "Path to the p12 certificate file",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :certificate_base64,
                                       env_name: "MACOS_CERTIFICATE",
                                       description: "Base64 encoded p12 certificate",
                                       optional: true,
                                       sensitive: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :certificate_password,
                                       env_name: "MACOS_CERTIFICATE_PWD",
                                       description: "Password for the p12 certificate",
                                       optional: true,
                                       sensitive: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :identity_id,
                                       env_name: "MACOS_IDENTITY_ID",
                                       description: "Signing identity ID (Team ID)",
                                       optional: true,
                                       type: String),
        ]
      end
    end
  end
end

