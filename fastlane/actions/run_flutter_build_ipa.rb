module Fastlane
  module Actions
    class RunFlutterBuildIpaAction < Action
      def self.run(params)
        sh "flutter clean"
        sh "flutter pub get"
        sh "flutter build ios --config-only"
        sh "flutter build ipa"
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
