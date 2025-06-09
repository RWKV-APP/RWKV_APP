module Fastlane
  module Actions
    class RunFlutterBuildApkAction < Action
      def self.run(params)
        sh "flutter clean"
        sh "flutter pub get"
        sh "flutter build apk --config-only"
        sh "flutter build apk"
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
