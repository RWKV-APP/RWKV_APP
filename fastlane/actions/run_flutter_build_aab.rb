module Fastlane
  module Actions
    class RunFlutterBuildAabAction < Action
      def self.run(params)
        sh "flutter clean"
        sh "flutter pub get"
        sh "flutter build appbundle"
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
