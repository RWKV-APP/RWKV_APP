require "yaml"

module Fastlane
  module Actions
    class RawChangeAnalysisOptionsAction < Action
      def self.run(params)
        puts "✅ Toggling prefer_const rules"
        analysis_options_path = "analysis_options.yaml"
        content = File.read(analysis_options_path)

        # Determine current state using first rule
        first_rule = "prefer_const_constructors"
        current_value = content.match(/^\s*#{Regexp.escape(first_rule)}:\s*(\w+)/)[1]
        new_value = current_value == "true" ? "false" : "true"

        # Update all three rules
        %w[
          prefer_const_constructors
          prefer_const_constructors_in_immutables
          prefer_const_literals_to_create_immutables
        ].each do |rule|
          content.gsub!(/(^\s*#{Regexp.escape(rule)}:\s*)(\w+)/, "\\1#{new_value}")
        end

        File.write(analysis_options_path, content)
        return new_value
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
