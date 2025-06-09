require "yaml"

module Fastlane
  module Actions
    class RawIncreaseBuildNumberAction < Action
      def self.run(params)
        puts "✅ increase build number"

        pubspec_path = "pubspec.yaml"
        yaml_content = File.read(pubspec_path)
        pubspec = YAML.load_file(pubspec_path)

        version = pubspec["version"]
        puts "version: #{version}"
        build_number = version.split("+")[1]
        new_build_number = build_number.to_i + 1
        new_version = "#{version.split("+")[0]}+#{new_build_number}"

        yaml_content.gsub!(/(version:\s+)#{Regexp.escape(version)}/, "\\1#{new_version}")
        File.write(pubspec_path, yaml_content)

        return new_build_number
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
