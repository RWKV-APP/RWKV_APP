# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'apple_auth_gate'

class RwkvAppleAuthGateTest < Minitest::Test
  def teardown
    RwkvAppleAuthGate.finish_fresh_session_environment
  end

  def test_default_path_selects_visible_apple_id_preauthentication
    mode = RwkvAppleAuthGate.resolve(
      requested_mode: nil,
      api_key_configured: false,
      stdin_tty: true,
      stdout_tty: true,
    )

    assert_equal :apple_id_preauthentication, mode
  end

  def test_default_path_refuses_background_execution_before_apple_login
    error = assert_raises(RwkvAppleAuthGate::GateError) do
      RwkvAppleAuthGate.resolve(
        requested_mode: nil,
        api_key_configured: false,
        stdin_tty: false,
        stdout_tty: false,
      )
    end

    assert_match 'apple_auth_tty_required', error.message
  end

  def test_explicit_api_key_mode_is_non_interactive
    mode = RwkvAppleAuthGate.resolve(
      requested_mode: 'api_key',
      api_key_configured: true,
      stdin_tty: false,
      stdout_tty: false,
    )

    assert_equal :api_key, mode
  end

  def test_explicit_api_key_mode_requires_configuration
    error = assert_raises(RwkvAppleAuthGate::GateError) do
      RwkvAppleAuthGate.resolve(
        requested_mode: 'api_key',
        api_key_configured: false,
        stdin_tty: false,
        stdout_tty: false,
      )
    end

    assert_match 'apple_auth_api_key_required', error.message
  end

  def test_invalid_mode_is_rejected
    error = assert_raises(RwkvAppleAuthGate::GateError) do
      RwkvAppleAuthGate.resolve(
        requested_mode: 'automatic',
        api_key_configured: true,
        stdin_tty: true,
        stdout_tty: true,
      )
    end

    assert_match 'apple_auth_mode_invalid', error.message
  end

  def test_fresh_session_environment_ignores_old_sessions_and_restores_them
    env = {
      'SPACESHIP_COOKIE_PATH' => '/existing/cookies',
      'FASTLANE_SESSION' => 'existing-fastlane-session',
      'SPACESHIP_SESSION' => 'existing-spaceship-session',
      'SPACESHIP_2FA_SMS_DEFAULT_PHONE_NUMBER' => '+10000000000',
    }
    session_environment = RwkvAppleAuthGate::FreshSessionEnvironment.new(env: env).activate
    fresh_root = session_environment.root

    assert_equal fresh_root, env['SPACESHIP_COOKIE_PATH']
    refute env.key?('FASTLANE_SESSION')
    refute env.key?('SPACESHIP_SESSION')
    refute env.key?('SPACESHIP_2FA_SMS_DEFAULT_PHONE_NUMBER')
    assert_equal 'true', env['SPACESHIP_ONLY_ALLOW_INTERACTIVE_2FA']
    assert Dir.exist?(fresh_root)

    session_environment.cleanup

    assert_equal '/existing/cookies', env['SPACESHIP_COOKIE_PATH']
    assert_equal 'existing-fastlane-session', env['FASTLANE_SESSION']
    assert_equal 'existing-spaceship-session', env['SPACESHIP_SESSION']
    assert_equal '+10000000000', env['SPACESHIP_2FA_SMS_DEFAULT_PHONE_NUMBER']
    refute env.key?('SPACESHIP_ONLY_ALLOW_INTERACTIVE_2FA')
    refute Dir.exist?(fresh_root)
  end

  def test_fastfile_authenticates_before_version_build_or_upload
    fastfile = File.read(File.expand_path('../../fastlane/Fastfile', __dir__))

    all_preauth = fastfile.index("if upload_to_testflight\n    ios_preflight_app_store_connect_auth(params)")
    version_effect = fastfile.index('build_number = raw_increase_build_number()')
    assert all_preauth, 'all lane must contain Apple preauthentication'
    assert version_effect, 'all lane must contain the version effect'
    assert_operator all_preauth, :<, version_effect

    preauth_method = fastfile.split('def ios_preauthenticate_with_apple_id(context)', 2).last
    preauth_method = preauth_method&.split("\ndef ios_cleanup_app_store_connect_context", 2)&.first
    assert preauth_method, 'Apple ID preauthentication helper must exist'
    assert_match 'Spaceship::ConnectAPI.login', preauth_method
    refute_match(/run_flutter_build_ipa|ipa_path|upload_to_testflight/, preauth_method)
  end
end
