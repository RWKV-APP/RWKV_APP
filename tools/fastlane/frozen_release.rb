require 'digest'
require 'fileutils'
require 'json'
require 'open3'
require 'tmpdir'
require 'timeout'

module RwkvFrozenRelease
  REPOSITORY = 'RWKV-APP/RWKV_APP'

  def self.run!(*arguments)
    output, error, status = Timeout.timeout(900) { Open3.capture3(*arguments) }
    raise "Release command failed: #{error}" unless status.success?
    output
  end

  def self.asset(version, name)
    release = JSON.parse(run!('gh', 'api', "repos/#{REPOSITORY}/releases/tags/#{version}"))
    raise 'The base release must already be published' if release['draft'] || release['tag_name'] != version
    release.fetch('assets').find { |item| item['name'] == name }
  end

  def self.verify!(path, metadata)
    digest = "sha256:#{Digest::SHA256.file(path).hexdigest}"
    unless File.size(path) == metadata['size'] && digest == metadata['digest']
      raise "Release asset differs from the accepted bytes: #{File.basename(path)}"
    end
    path
  end

  def self.resume_macos(project_root, version, build, identity: nil)
    identity = public_identity(identity, version, build) unless identity.nil?
    name = "rwkv_chat_#{version}_#{build}_macos.dmg"
    metadata = asset(version, name)
    return nil if metadata.nil?
    verify_provenance(version, "#{name}.provenance.json", identity, artifact_metadata(name, metadata)) unless identity.nil?

    destination = File.join(project_root, 'build', 'release-resume', name)
    return verify!(destination, metadata) if File.file?(destination)

    Dir.mktmpdir('rwkv-release-') do |directory|
      run!('gh', 'release', 'download', version, '--repo', REPOSITORY,
           '--pattern', name, '--dir', directory)
      downloaded = verify!(File.join(directory, name), metadata)
      FileUtils.mkdir_p(File.dirname(destination))
      FileUtils.mv(downloaded, destination)
    end
    destination
  end

  def self.publish_macos(version, path, identity: nil)
    metadata = asset(version, File.basename(path))
    existing = !metadata.nil?
    proof_name = "#{File.basename(path)}.provenance.json"
    unless identity.nil?
      identity = public_identity(identity, version)
      expected_name = "rwkv_chat_#{version}_#{identity.fetch('build')}_macos.dmg"
      raise 'macOS artifact name does not match its release identity' unless File.basename(path) == expected_name
      verify_provenance(version, proof_name, identity, artifact_metadata(expected_name, metadata)) if existing
    end
    if metadata.nil?
      # No --clobber: a concurrent or different upload must fail instead of replacing bytes.
      run!('gh', 'release', 'upload', version, path, '--repo', REPOSITORY)
      metadata = asset(version, File.basename(path))
    end
    raise 'Uploaded macOS asset is missing from the release' if metadata.nil?
    verify!(path, metadata)
    publish_provenance(version, proof_name, identity, file_metadata(path)) if !identity.nil? && !existing
    path
  end

  def self.public_identity(identity, version, build = nil)
    value = JSON.parse(JSON.generate(identity))
    fields = %w[sourceCommit releaseManifestSha256 adapterCommit nativeCommit nativeTag nativeFiles version build]
    unless value.is_a?(Hash) && value.keys.sort == fields.sort && value['version'] == version &&
           version.is_a?(String) && version.match?(/\A[0-9]+\.[0-9]+\.[0-9]+(?:[-+][0-9A-Za-z.-]+)?\z/) &&
           (build.nil? || value['build'].to_s == build.to_s)
      raise 'Release provenance identity is incomplete or does not match the version/build'
    end
    commits = %w[sourceCommit adapterCommit nativeCommit]
    files = value['nativeFiles']
    unless commits.all? { |key| value[key].is_a?(String) && value[key].match?(/\A[0-9a-f]{40}\z/) } &&
           value['releaseManifestSha256'].is_a?(String) && value['releaseManifestSha256'].match?(/\A[0-9a-f]{64}\z/) &&
           value['nativeTag'].is_a?(String) && value['nativeTag'].match?(/\A[\w.-]+\z/) &&
           !%w[latest master main].include?(value['nativeTag']) && value['build'].to_s.match?(/\A[1-9][0-9]*\z/) &&
           files.is_a?(Array) && !files.empty? && files.all? { |file|
             file.is_a?(Hash) && file.keys.sort == %w[path platform sha256 size] &&
               %w[ios macos].include?(file['platform']) && file['path'].is_a?(String) &&
               file['path'].start_with?("#{file['platform']}/") && !file['path'].match?(/[\\:\x00-\x1f]/) &&
               file['path'].split('/', -1).none? { |part| ['', '.', '..'].include?(part) } &&
               file['size'].is_a?(Integer) && file['size'].positive? &&
               file['sha256'].is_a?(String) && file['sha256'].match?(/\A[0-9a-f]{64}\z/)
           } && files.map { |file| file['path'] }.uniq.length == files.length
      raise 'Release provenance must contain only public commit/hash identities and relative Apple native files'
    end
    value
  end

  def self.artifact_metadata(name, metadata)
    { 'name' => name, 'size' => metadata.fetch('size'), 'sha256' => metadata.fetch('digest').delete_prefix('sha256:') }
  end

  def self.file_metadata(path)
    { 'name' => File.basename(path), 'size' => File.size(path), 'sha256' => Digest::SHA256.file(path).hexdigest }
  end

  def self.verify_provenance(version, name, identity, artifact = nil)
    identity = public_identity(identity, version)
    metadata = asset(version, name)
    raise "Release provenance is missing: #{name}; refusing to reuse an unproven build" if metadata.nil?
    raise 'Release provenance exceeds the metadata size limit' unless metadata['size'].is_a?(Integer) && metadata['size'].between?(1, 1024 * 1024)
    proof = Dir.mktmpdir('rwkv-provenance-') do |directory|
      run!('gh', 'release', 'download', version, '--repo', REPOSITORY, '--pattern', name, '--dir', directory)
      JSON.parse(File.read(verify!(File.join(directory, name), metadata)))
    end
    output = proof['artifact'] if proof.is_a?(Hash)
    unless proof.is_a?(Hash) && proof.keys.sort == %w[artifact identity schemaVersion] &&
           proof['schemaVersion'] == 1 && proof['identity'] == identity && output.is_a?(Hash) &&
           output.keys.sort == %w[name sha256 size] && output['name'].is_a?(String) &&
           output['name'].match?(/\A[^\\\/:]+\z/) && output['size'].is_a?(Integer) && output['size'].positive? &&
           output['sha256'].is_a?(String) && output['sha256'].match?(/\A[0-9a-f]{64}\z/) &&
           (artifact.nil? || output == artifact)
      raise "Release provenance differs from the current source/native identity or artifact: #{name}"
    end
    proof
  end

  def self.publish_provenance(version, name, identity, artifact)
    identity = public_identity(identity, version)
    return verify_provenance(version, name, identity, artifact) unless asset(version, name).nil?
    Dir.mktmpdir('rwkv-provenance-') do |directory|
      path = File.join(directory, name)
      File.write(path, JSON.pretty_generate({ 'schemaVersion' => 1, 'identity' => identity, 'artifact' => artifact }) + "\n")
      run!('gh', 'release', 'upload', version, path, '--repo', REPOSITORY)
      metadata = asset(version, name)
      raise "Uploaded release provenance is missing: #{name}" if metadata.nil?
      verify!(path, metadata)
    end
    verify_provenance(version, name, identity, artifact)
  end

  def self.verify_ios_provenance(version, build, identity)
    identity = public_identity(identity, version, build)
    proof = verify_provenance(version, "rwkv_chat_#{version}_#{build}_ios.provenance.json", identity)
    raise 'iOS provenance must identify an IPA' unless proof.fetch('artifact').fetch('name').end_with?('.ipa')
    proof
  end

  def self.publish_ios_provenance(version, build, ipa_path, identity)
    identity = public_identity(identity, version, build)
    raise 'iOS provenance requires a nonempty IPA' unless File.extname(ipa_path) == '.ipa' && File.size(ipa_path).positive?
    publish_provenance(version, "rwkv_chat_#{version}_#{build}_ios.provenance.json", identity, file_metadata(ipa_path))
  end
end
