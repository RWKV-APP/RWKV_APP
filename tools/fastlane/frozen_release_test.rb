require 'minitest/autorun'
require 'tmpdir'
require_relative 'frozen_release'

class RwkvFrozenReleaseTest < Minitest::Test
  VERSION = '4.8.0'
  BUILD = 755
  DMG = "rwkv_chat_#{VERSION}_#{BUILD}_macos.dmg"
  IOS_PROOF = "rwkv_chat_#{VERSION}_#{BUILD}_ios.provenance.json"

  def identity
    { 'sourceCommit' => 'a' * 40, 'releaseManifestSha256' => 'b' * 64,
      'adapterCommit' => 'c' * 40, 'nativeCommit' => 'd' * 40,
      'nativeTag' => '4.8.0-native.4', 'version' => VERSION, 'build' => BUILD,
      'nativeFiles' => [{ 'platform' => 'macos', 'path' => 'macos/librwkv_mobile.dylib',
                          'size' => 10, 'sha256' => 'e' * 64 }] }
  end

  def metadata(bytes)
    { 'size' => bytes.bytesize, 'digest' => "sha256:#{Digest::SHA256.hexdigest(bytes)}" }
  end

  def proof(name, bytes, release_identity = identity)
    { 'schemaVersion' => 1, 'identity' => release_identity,
      'artifact' => { 'name' => name, 'size' => bytes.bytesize, 'sha256' => Digest::SHA256.hexdigest(bytes) } }
  end

  def with_remote(remote = {}, fail_upload: nil)
    calls = []
    lookup = ->(version, name) { assert_equal VERSION, version; metadata(remote[name]) if remote.key?(name) }
    command = lambda do |*args|
      calls << args
      refute_includes args, '--clobber'
      assert_equal ['gh', 'release'], args.first(2)
      assert_equal VERSION, args[3]
      if args[2] == 'download'
        name = args[args.index('--pattern') + 1]
        File.binwrite(File.join(args[args.index('--dir') + 1], name), remote.fetch(name))
      elsif args[2] == 'upload'
        name = File.basename(args[4])
        raise 'Simulated interrupted upload' if name == fail_upload
        raise 'Refusing replacement' if remote.key?(name)
        remote[name] = File.binread(args[4])
      else
        flunk("Unexpected command: #{args}")
      end
      ''
    end
    RwkvFrozenRelease.stub(:asset, lookup) do
      RwkvFrozenRelease.stub(:run!, command) { yield remote, calls }
    end
  end

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

  def test_existing_dmg_without_provenance_cannot_be_adopted_by_resume_or_publish
    Dir.mktmpdir do |directory|
      path = File.join(directory, DMG)
      File.write(path, 'accepted')
      with_remote({ DMG => 'accepted' }) do |_, calls|
        error = assert_raises(RuntimeError) { RwkvFrozenRelease.resume_macos(directory, VERSION, BUILD, identity: identity) }
        assert_match(/provenance is missing/, error.message)
        assert_raises(RuntimeError) { RwkvFrozenRelease.publish_macos(VERSION, path, identity: identity) }
        assert_empty calls
      end
    end
  end

  def test_resume_requires_both_exact_source_identity_and_artifact_digest
    [->(p) { p['identity']['sourceCommit'] = 'f' * 40 },
     ->(p) { p['artifact']['sha256'] = 'f' * 64 }].each do |change|
      altered = proof(DMG, 'accepted')
      change.call(altered)
      with_remote({ DMG => 'accepted', "#{DMG}.provenance.json" => JSON.generate(altered) }) do |_, calls|
        Dir.mktmpdir do |directory|
          assert_raises(RuntimeError) { RwkvFrozenRelease.resume_macos(directory, VERSION, BUILD, identity: identity) }
        end
        assert_equal ["#{DMG}.provenance.json"], calls.map { |args| args[args.index('--pattern') + 1] }
      end
    end
  end

  def test_verified_resume_downloads_exact_bytes_and_rechecks_a_local_cached_dmg
    remote = { DMG => 'accepted', "#{DMG}.provenance.json" => JSON.generate(proof(DMG, 'accepted')) }
    with_remote(remote) do |_, calls|
      Dir.mktmpdir do |directory|
        path = RwkvFrozenRelease.resume_macos(directory, VERSION, BUILD, identity: identity)
        assert_equal 'accepted', File.read(path)
        assert_equal path, RwkvFrozenRelease.resume_macos(directory, VERSION, BUILD, identity: identity)
        assert_equal 1, calls.count { |args| args.include?('--pattern') && args[args.index('--pattern') + 1] == DMG }
        File.write(path, 'wrong cached bytes')
        assert_raises(RuntimeError) { RwkvFrozenRelease.resume_macos(directory, VERSION, BUILD, identity: identity) }
      end
    end
  end

  def test_new_macos_upload_publishes_proof_after_dmg_and_is_idempotent
    Dir.mktmpdir do |directory|
      path = File.join(directory, DMG)
      File.write(path, 'new accepted DMG')
      with_remote do |remote, calls|
        assert_equal path, RwkvFrozenRelease.publish_macos(VERSION, path, identity: identity)
        assert_equal [DMG, "#{DMG}.provenance.json"], remote.keys
        assert_equal proof(DMG, File.read(path)), JSON.parse(remote.fetch("#{DMG}.provenance.json"))
        refute_includes remote.fetch("#{DMG}.provenance.json"), directory
        RwkvFrozenRelease.publish_macos(VERSION, path, identity: identity)
        assert_equal 2, calls.count { |args| args[2] == 'upload' }
        File.write(path, 'different DMG')
        assert_raises(RuntimeError) { RwkvFrozenRelease.publish_macos(VERSION, path, identity: identity) }
      end
    end
  end

  def test_interruption_after_dmg_upload_does_not_authorize_unproven_resume
    Dir.mktmpdir do |directory|
      path = File.join(directory, DMG)
      File.write(path, 'accepted')
      with_remote({}, fail_upload: "#{DMG}.provenance.json") do |remote, _|
        assert_raises(RuntimeError) { RwkvFrozenRelease.publish_macos(VERSION, path, identity: identity) }
        assert_equal [DMG], remote.keys
        assert_raises(RuntimeError) { RwkvFrozenRelease.resume_macos(directory, VERSION, BUILD, identity: identity) }
      end
    end
  end

  def test_ios_uploads_only_proof_and_checks_full_identity_before_reuse
    Dir.mktmpdir do |directory|
      ipa = File.join(directory, 'RWKVChat.ipa')
      File.write(ipa, 'accepted IPA')
      with_remote do |remote, calls|
        assert_raises(RuntimeError) { RwkvFrozenRelease.verify_ios_provenance(VERSION, BUILD, identity) }
        result = RwkvFrozenRelease.publish_ios_provenance(VERSION, BUILD, ipa, identity)
        assert_equal [IOS_PROOF], remote.keys
        assert_equal proof('RWKVChat.ipa', 'accepted IPA'), result
        assert_equal result, RwkvFrozenRelease.verify_ios_provenance(VERSION, BUILD, identity)
        assert_equal result, RwkvFrozenRelease.publish_ios_provenance(VERSION, BUILD, ipa, identity)
        assert_equal 1, calls.count { |args| args[2] == 'upload' }
        assert_raises(RuntimeError) { RwkvFrozenRelease.verify_ios_provenance(VERSION, BUILD + 1, identity) }
        changed = identity.merge('sourceCommit' => 'f' * 40)
        assert_raises(RuntimeError) { RwkvFrozenRelease.verify_ios_provenance(VERSION, BUILD, changed) }
        File.write(ipa, 'different IPA')
        assert_raises(RuntimeError) { RwkvFrozenRelease.publish_ios_provenance(VERSION, BUILD, ipa, identity) }
      end
    end
  end

  def test_private_paths_and_unknown_identity_fields_never_reach_publication
    invalid = [identity.merge('machine' => 'private'), identity, identity]
    invalid[1]['nativeFiles'][0]['path'] = 'C:/private/native.dylib'
    invalid[2]['nativeFiles'][0]['path'] = 'macos/../private/native.dylib'
    with_remote do |_, calls|
      invalid.each do |value|
        assert_raises(RuntimeError) { RwkvFrozenRelease.publish_ios_provenance(VERSION, BUILD, 'unused.ipa', value) }
      end
      unsafe_version = '../4.8.0'
      assert_raises(RuntimeError) do
        RwkvFrozenRelease.publish_ios_provenance(unsafe_version, BUILD, 'unused.ipa', identity.merge('version' => unsafe_version))
      end
      assert_empty calls
    end
  end
end
