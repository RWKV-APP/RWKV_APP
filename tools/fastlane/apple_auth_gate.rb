# frozen_string_literal: true

module RwkvAppleAuthGate
  INTERACTIVE_ACKNOWLEDGEMENT = 'ALLOW_ONE_INTERACTIVE_APPLE_AUTH_ATTEMPT'

  class GateError < StandardError; end

  def self.checkpoint_complete?(path:, version:)
    return false if path.nil? || path.to_s.strip.empty?
    return false unless File.exist?(path)

    require 'json'

    checkpoint = JSON.parse(File.read(path))
    unless checkpoint['status'] == 'succeeded' && checkpoint['version'] == version
      raise GateError,
            "testflight_checkpoint_mismatch: #{path} 不属于当前版本 #{version}，拒绝跳过 TestFlight"
    end

    true
  rescue JSON::ParserError
    raise GateError, "testflight_checkpoint_invalid: #{path} 不是有效的 JSON 检查点"
  end

  def self.write_checkpoint(path:, version:)
    return if path.nil? || path.to_s.strip.empty?

    require 'fileutils'
    require 'json'
    require 'time'

    expanded_path = File.expand_path(path)
    FileUtils.mkdir_p(File.dirname(expanded_path))
    temporary_path = "#{expanded_path}.tmp-#{Process.pid}"
    payload = {
      version: version,
      status: 'succeeded',
      recorded_at: Time.now.utc.iso8601,
    }
    File.open(temporary_path, File::WRONLY | File::CREAT | File::TRUNC, 0o600) do |file|
      file.write(JSON.pretty_generate(payload))
      file.write("\n")
    end
    File.rename(temporary_path, expanded_path)
    File.chmod(0o600, expanded_path)
  ensure
    File.delete(temporary_path) if defined?(temporary_path) && File.exist?(temporary_path)
  end

  def self.resolve(api_key_configured:, allow_interactive:, acknowledgement:, stdin_tty:, stdout_tty:)
    return :api_key if api_key_configured

    unless allow_interactive
      raise GateError,
            'apple_auth_preflight_required: TestFlight 默认只允许 App Store Connect API key；' \
            '未向 Apple 发起登录，也不会发送验证码'
    end

    unless acknowledgement == INTERACTIVE_ACKNOWLEDGEMENT
      raise GateError,
            "apple_auth_acknowledgement_required: 人工认证必须显式传入 " \
            "interactive_apple_auth_acknowledgement:#{INTERACTIVE_ACKNOWLEDGEMENT}"
    end

    unless stdin_tty && stdout_tty
      raise GateError,
            'apple_auth_tty_required: 人工 Apple 认证只能在可见的交互式终端运行；' \
            '后台任务和重定向日志不得触发验证码'
    end

    :interactive_once
  end
end
