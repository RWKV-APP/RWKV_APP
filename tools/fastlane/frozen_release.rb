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

  def self.resume_macos(project_root, version, build)
    name = "rwkv_chat_#{version}_#{build}_macos.dmg"
    metadata = asset(version, name)
    return nil if metadata.nil?

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

  def self.publish_macos(version, path)
    metadata = asset(version, File.basename(path))
    if metadata.nil?
      # No --clobber: a concurrent or different upload must fail instead of replacing bytes.
      run!('gh', 'release', 'upload', version, path, '--repo', REPOSITORY)
      metadata = asset(version, File.basename(path))
    end
    raise 'Uploaded macOS asset is missing from the release' if metadata.nil?
    verify!(path, metadata)
  end
end
