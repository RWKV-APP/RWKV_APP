require "yaml"

module Fastlane
  module Actions
    class RawIncreaseVersionNumberAction < Action
      def self.run(params)
        puts "✅ increase version number"

        pubspec_path = "pubspec.yaml"
        yaml_content = File.read(pubspec_path)
        pubspec = YAML.load_file(pubspec_path)

        versionString = pubspec["version"]

        version_number = versionString.split("+")[0]
        build_number = versionString.split("+")[1]

        version_number_array = version_number.split(".")
        version_number_array[2] = version_number_array[2].to_i + 1
        new_version_number = version_number_array.join(".")

        new_version_with_build = "#{new_version_number}+#{build_number}"

        yaml_content.gsub!(/(version:\s+)#{Regexp.escape(versionString)}/, "\\1#{new_version_with_build}")
        File.write(pubspec_path, yaml_content)

        return new_version_number
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
