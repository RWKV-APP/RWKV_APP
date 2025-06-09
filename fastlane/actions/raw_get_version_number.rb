require "yaml"

module Fastlane
  module Actions
    class RawGetVersionNumberAction < Action
      def self.run(params)
        puts "✅ get version number"

        pubspec_path = "pubspec.yaml"
        yaml_content = File.read(pubspec_path)
        pubspec = YAML.load_file(pubspec_path)

        versionString = pubspec["version"]
        version_number = versionString.split("+")[0]

        return version_number
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
