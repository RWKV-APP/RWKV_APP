require 'minitest/autorun'

# Execute the real build actions with all shell and symbol-upload effects stubbed.
module Fastlane
  module UI
    def self.message(*)
    end
  end

  module Actions
    class Action
      def self.sh(*)
        raise 'A build test must never execute a real command'
      end
    end
  end
end

require_relative '../../fastlane/actions/run_flutter_build_macos_dmg'
require_relative '../../fastlane/actions/run_flutter_build_ipa'

class AppleBuildTest < Minitest::Test
  class VerificationFailure < StandardError; end

  ACTIONS = {
    'macos' => Fastlane::Actions::RunFlutterBuildMacosDmgAction,
    'ios' => Fastlane::Actions::RunFlutterBuildIpaAction,
  }.freeze

  def run_action(action, calls, fail_at: nil)
    shell = lambda do |*args|
      calls << args
      if args.include?('--verify-apple-build-inputs')
        phase = args.include?('--require-pods') ? :after_build : :before_build
        raise VerificationFailure, phase.to_s if phase == fail_at
      end
      ''
    end
    symbols = lambda do |*|
      calls << [:symbols]
      # Stop before macOS signing/packaging, which needs real platform artifacts.
      throw :verified
    end
    action.stub(:sh, shell) do
      action.stub(:upload_sentry_symbols, symbols) do
        catch(:verified) { action.run(frozen_release: true) }
      end
    end
  end

  ACTIONS.each do |platform, action|
    define_method("test_#{platform}_frozen_build_verifies_before_and_after_build") do
      calls = []
      run_action(action, calls)
      assert_equal 6, calls.length
      assert_equal ['flutter', 'clean'], calls[0]
      assert_equal ['flutter', 'pub', 'get', '--enforce-lockfile'], calls[1]
      assert_equal ['python3', 'scripts/release_identity.py', '--verify-apple-build-inputs', '--platform', platform], calls[2]
      assert_match(/flutter build #{platform == 'ios' ? 'ipa' : 'macos'}\b/, calls[3].first)
      assert_includes calls[3].first, '--no-pub'
      assert_equal ['--verify-apple-build-inputs', '--platform', platform, '--require-pods'], calls[4].drop(2)
      assert_equal [:symbols], calls[5]
    end

    define_method("test_#{platform}_preverification_failure_stops_before_build") do
      calls = []
      error = assert_raises(VerificationFailure) { run_action(action, calls, fail_at: :before_build) }
      assert_equal 'before_build', error.message
      assert_equal 3, calls.length
      refute calls.any? { |args| args.first.to_s.include?('flutter build') }
      refute_includes calls, [:symbols]
    end

    define_method("test_#{platform}_postverification_failure_stops_before_symbol_upload") do
      calls = []
      error = assert_raises(VerificationFailure) { run_action(action, calls, fail_at: :after_build) }
      assert_equal 'after_build', error.message
      assert_equal 5, calls.length
      assert_includes calls.last, '--require-pods'
      refute_includes calls, [:symbols]
    end
  end
end
