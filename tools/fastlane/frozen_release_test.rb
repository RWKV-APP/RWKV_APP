require 'minitest/autorun'
require 'tmpdir'
require_relative 'frozen_release'

class RwkvFrozenReleaseTest < Minitest::Test
  def test_resume_reuses_only_verified_bytes_and_never_overwrites_a_conflict
    Dir.mktmpdir do |directory|
      path = File.join(directory, 'rwkv_chat_4.8.0_755_macos.dmg')
      File.write(path, 'accepted release')
      metadata = { 'size' => File.size(path), 'digest' => "sha256:#{Digest::SHA256.file(path).hexdigest}" }
      RwkvFrozenRelease.stub(:asset, metadata) do
        RwkvFrozenRelease.stub(:run!, ->(*) { flunk('An existing asset must not be uploaded again') }) do
          assert_equal path, RwkvFrozenRelease.publish_macos('4.8.0', path)
          File.write(path, 'different bytes!')
          assert_raises(RuntimeError) { RwkvFrozenRelease.publish_macos('4.8.0', path) }
        end
      end
    end
  end
end
