require 'yaml'

module Fastlane
  module Actions
    class GlobalConfigReplaceAction < Action
      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :env,
            description: 'Target environment name',
            optional: false,
            type: String,
          ),
        ]
      end

      def self.run(params)
        config_path = File.join(__dir__, '..', 'environments.yml')
        UI.user_error!("Missing environments config file at #{config_path}") unless File.exist?(config_path)

        environments = YAML.load_file(config_path)
        env = params[:env]
        config = environments[env]
        UI.user_error!("Unknown environment: #{env}") unless config

        # Define file patterns to process
        target_files = [
          # 代码文件
          '**/*.dart',
          '**/*.swift',
          '**/*.kt',
          '**/*.m',
          '**/*.h',
          '**/*.dart',

          # 配置文件
          '**/*.yaml',
          '**/*.yml',
          '**/*.json',
          '**/*.plist',
          '**/*.xml',
          '**/*.pbxproj',
          '**/*.xcconfig',

          # 构建文件
          '**/Podfile',
          '**/*.gradle',
          '**/*.properties',

          # Fastlane文件
          'fastlane/Appfile',
          'fastlane/Fastfile',

          # Windows/Linux
          '**/*.rc',
          '**/CMakeLists.txt',
        ]

        # 添加排除模式（替代原来的exclude_files）
        exclude_patterns = [
          '**/build/**',
          '**/.git/**',
          '**/Pods/**',
          '**/Carthage/**',
          '**/vendor/**',
          '**/node_modules/**',
          'fastlane/actions/**',  # 排除action文件自身
          'fastlane/environments.yml',
          '**/gen/**',
          '**/l10n/**',
          'assets/config/**',
        ]

        # 遍历 key 值
        config.each do |key, value|
          froms = environments[key]
          to = value

          # Perform safe replacement
          Dir.glob(target_files, File::FNM_CASEFOLD).each do |file|
            next if exclude_patterns.any? { |pattern| File.fnmatch?(pattern, file) }
            replace_in_file(file, froms, to)
          end
        end

        UI.success("✅ Global replacement complete for #{env} environment")
      end

      def self.replace_in_file(path, from, to)
        content = File.read(path)
        original = content.dup
        from.each do |from|
          content.gsub!(from, to)
        end
        File.write(path, content) if content != original
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end
    end
  end
end
