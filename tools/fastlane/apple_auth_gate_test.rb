# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require_relative 'apple_auth_gate'

class RwkvAppleAuthGateTest < Minitest::Test
  def test_api_key_is_non_interactive
    mode = RwkvAppleAuthGate.resolve(
      api_key_configured: true,
      allow_interactive: false,
      acknowledgement: nil,
      stdin_tty: false,
      stdout_tty: false,
    )

    assert_equal :api_key, mode
  end

  def test_default_path_stops_before_apple_login
    error = assert_raises(RwkvAppleAuthGate::GateError) do
      RwkvAppleAuthGate.resolve(
        api_key_configured: false,
        allow_interactive: false,
        acknowledgement: nil,
        stdin_tty: true,
        stdout_tty: true,
      )
    end

    assert_match 'apple_auth_preflight_required', error.message
  end

  def test_interactive_path_requires_exact_acknowledgement
    error = assert_raises(RwkvAppleAuthGate::GateError) do
      RwkvAppleAuthGate.resolve(
        api_key_configured: false,
        allow_interactive: true,
        acknowledgement: 'yes',
        stdin_tty: true,
        stdout_tty: true,
      )
    end

    assert_match 'apple_auth_acknowledgement_required', error.message
  end

  def test_interactive_path_refuses_background_execution
    error = assert_raises(RwkvAppleAuthGate::GateError) do
      RwkvAppleAuthGate.resolve(
        api_key_configured: false,
        allow_interactive: true,
        acknowledgement: RwkvAppleAuthGate::INTERACTIVE_ACKNOWLEDGEMENT,
        stdin_tty: false,
        stdout_tty: false,
      )
    end

    assert_match 'apple_auth_tty_required', error.message
  end

  def test_interactive_path_allows_one_visible_attempt
    mode = RwkvAppleAuthGate.resolve(
      api_key_configured: false,
      allow_interactive: true,
      acknowledgement: RwkvAppleAuthGate::INTERACTIVE_ACKNOWLEDGEMENT,
      stdin_tty: true,
      stdout_tty: true,
    )

    assert_equal :interactive_once, mode
  end

  def test_success_checkpoint_is_version_bound_and_private
    Dir.mktmpdir do |directory|
      checkpoint_path = File.join(directory, 'testflight.json')
      RwkvAppleAuthGate.write_checkpoint(path: checkpoint_path, version: '4.7.0+752')

      assert RwkvAppleAuthGate.checkpoint_complete?(
        path: checkpoint_path,
        version: '4.7.0+752',
      )
      assert_equal 0o600, File.stat(checkpoint_path).mode & 0o777
      assert_raises(RwkvAppleAuthGate::GateError) do
        RwkvAppleAuthGate.checkpoint_complete?(
          path: checkpoint_path,
          version: '4.7.1+753',
        )
      end
    end
  end
end
