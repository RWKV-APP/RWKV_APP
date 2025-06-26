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

        # 获取所有符合条件的文件
        all_files = Dir.glob(target_files, File::FNM_CASEFOLD).reject do |file|
          exclude_patterns.any? { |pattern| File.fnmatch?(pattern, file) }
        end

        # 遍历 key 值 (保持顺序处理配置项，避免依赖问题)
        config.each do |key, value|
          froms = environments[key]
          to = value

          # 多线程处理文件
          process_files_parallel(all_files, froms, to)
        end

        UI.success("✅ Global replacement complete for #{env} environment")
      end

      def self.process_files_parallel(files, from_patterns, to_value)
        # 确定线程数量，避免创建过多线程
        thread_count = [files.size, 10].min
        return if thread_count == 0

        # 将文件分组
        file_groups = files.each_slice((files.size / thread_count.to_f).ceil).to_a

        threads = []

        file_groups.each do |file_group|
          threads << Thread.new do
            file_group.each do |file|
              replace_in_file(file, from_patterns, to_value)
            end
          end
        end

        # 等待所有线程完成
        threads.each(&:join)
      end

      def self.replace_in_file(path, from_patterns, to)
        begin
          content = File.read(path)
          original = content.dup
          from_patterns.each do |from_pattern|
            content.gsub!(from_pattern, to)
          end
          File.write(path, content) if content != original
        rescue => e
          UI.error("Failed to process file #{path}: #{e.message}")
        end
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end
    end
  end
end
