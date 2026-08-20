# frozen_string_literal: true

module RwkvAppleAuthGate
  APPLE_ID_MODE = 'apple_id'
  API_KEY_MODE = 'api_key'
  SESSION_ENV_KEYS = %w[
    SPACESHIP_COOKIE_PATH
    FASTLANE_SESSION
    SPACESHIP_SESSION
    SPACESHIP_2FA_SMS_DEFAULT_PHONE_NUMBER
    SPACESHIP_ONLY_ALLOW_INTERACTIVE_2FA
  ].freeze

  class GateError < StandardError; end

  class FreshSessionEnvironment
    attr_reader :root

    def initialize(env: ENV)
      @env = env
      @original_values = {}
      @active = false
    end

    def active?
      @active
    end

    def activate
      return self if active?

      require 'tmpdir'

      @root = Dir.mktmpdir('rwkv_apple_auth_session')
      SESSION_ENV_KEYS.each do |key|
        @original_values[key] = @env.key?(key) ? [:present, @env[key]] : [:absent, nil]
      end

      @env['SPACESHIP_COOKIE_PATH'] = @root
      @env.delete('FASTLANE_SESSION')
      @env.delete('SPACESHIP_SESSION')
      @env.delete('SPACESHIP_2FA_SMS_DEFAULT_PHONE_NUMBER')
      @env['SPACESHIP_ONLY_ALLOW_INTERACTIVE_2FA'] = 'true'
      @active = true
      self
    rescue
      cleanup
      raise
    end

    def secure_cookie_files
      return unless active?

      Dir.glob(File.join(@root, 'spaceship', '**', 'cookie')).each do |path|
        File.chmod(0o600, path) if File.file?(path)
      end
    end

    def cleanup
      SESSION_ENV_KEYS.each do |key|
        original = @original_values[key]
        next if original.nil?

        if original.first == :present
          @env[key] = original.last
        else
          @env.delete(key)
        end
      end

      if !@root.nil? && Dir.exist?(@root)
        require 'fileutils'

        expanded_root = File.expand_path(@root)
        temporary_root = File.expand_path(Dir.tmpdir)
        unless File.dirname(expanded_root) == temporary_root &&
               File.basename(expanded_root).start_with?('rwkv_apple_auth_session')
          raise GateError, "apple_auth_session_cleanup_refused: 非预期临时目录 #{expanded_root}"
        end

        FileUtils.remove_entry(expanded_root)
      end

      @active = false
      @root = nil
      self
    end
  end

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

  def self.resolve(requested_mode:, api_key_configured:, stdin_tty:, stdout_tty:)
    normalized_mode = requested_mode.to_s.strip.downcase.tr('-', '_')
    normalized_mode = APPLE_ID_MODE if normalized_mode.empty?

    case normalized_mode
    when APPLE_ID_MODE
      unless stdin_tty && stdout_tty
        raise GateError,
              'apple_auth_tty_required: 默认 Apple ID 预认证只能在可见的交互式终端运行；' \
              '后台任务必须显式选择 api_key，且不会在此错误路径联系 Apple'
      end

      :apple_id_preauthentication
    when API_KEY_MODE
      unless api_key_configured
        raise GateError,
              'apple_auth_api_key_required: 已显式选择 api_key，但没有配置 App Store Connect API key'
      end

      :api_key
    else
      raise GateError,
            "apple_auth_mode_invalid: #{requested_mode.inspect}；可选值为 apple_id 或 api_key"
    end
  end

  def self.start_fresh_session_environment
    return @fresh_session_environment if @fresh_session_environment&.active?

    @fresh_session_environment = FreshSessionEnvironment.new.activate
    at_exit { finish_fresh_session_environment }
    @fresh_session_environment
  end

  def self.fresh_session_environment
    return nil unless @fresh_session_environment&.active?

    @fresh_session_environment
  end

  def self.finish_fresh_session_environment
    @fresh_session_environment&.cleanup
  ensure
    @fresh_session_environment = nil
  end
end
