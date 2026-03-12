require 'open3'
require 'shellwords'
require 'timeout'

module Fastlane
  module Actions
    class GithubReleaseAction < Action
      DEFAULT_GH_COMMAND_TIMEOUT_SECONDS = 60
      DEFAULT_GH_CREATE_TIMEOUT_SECONDS = 180
      DEFAULT_UPLOAD_TIMEOUT_SECONDS = 1200

      def self.run(params)
        UI.message("The github_release plugin is working.")

        repo = params[:repo]
        full_version = params[:version]
        file_path = params[:file_path]
        branch = params[:branch] || "dev"
        release_name = params[:release_name] || full_version
        release_notes = params[:release_notes] || "Release #{full_version}"
        upload_retry_count = (params[:upload_retry_count] || 3).to_i
        upload_timeout_seconds = (params[:upload_timeout_seconds] || DEFAULT_UPLOAD_TIMEOUT_SECONDS).to_i
        if upload_retry_count < 1
          UI.user_error!("upload_retry_count must be >= 1")
        end
        if upload_timeout_seconds < 30
          UI.user_error!("upload_timeout_seconds must be >= 30")
        end

        if repo.nil? || repo.empty?
          UI.user_error!("You have to provide a repo (e.g., 'RWKV-APP/RWKV_APP')")
        end

        if full_version.nil? || full_version.empty?
          UI.user_error!("You have to provide a version")
        end

        # Extract semantic version (e.g., "3.4.0" from "3.4.0+612")
        # Tag name should only be the semantic version, not including build number
        version_parts = full_version.split('+')
        version = version_parts[0].strip # e.g., "3.4.0"
        
        # Ensure version doesn't contain build number (safety check)
        if version.include?('+')
          UI.user_error!("Invalid version format: tag name should not contain '+'. Got: #{version}")
        end
        
        UI.message("Full version: #{full_version}, Tag name: #{version}")

        if file_path.nil? || !File.exist?(file_path)
          UI.user_error!("File not found at path: #{file_path}")
        end

        # Convert to absolute path
        file_path = File.expand_path(file_path)

        # Check if gh CLI is installed and authenticated
        unless system("which gh > /dev/null 2>&1")
          UI.user_error!("GitHub CLI (gh) is not installed. Please install it first: https://cli.github.com/")
        end

        # Check if user is authenticated
        auth_status = run_command(
          command: ['gh', 'auth', 'status'],
          timeout_seconds: DEFAULT_GH_COMMAND_TIMEOUT_SECONDS,
        )
        unless auth_status[:success]
          UI.user_error!("You are not authenticated with GitHub CLI. Please run: gh auth login. #{format_command_error(auth_status)}")
        end

        UI.message("Checking for existing release: #{version} (tag) in #{repo}")

        # Check if release exists (using semantic version as tag name)
        release_check = run_command(
          command: ['gh', 'release', 'view', version, '--repo', repo],
          timeout_seconds: DEFAULT_GH_COMMAND_TIMEOUT_SECONDS,
        )
        if release_check[:success]
          release_exists = true
        elsif not_found_result?(release_check)
          release_exists = false
        else
          UI.user_error!("Failed to inspect release #{version}: #{format_command_error(release_check)}")
        end

        if release_exists
          UI.message("Release #{version} already exists. Uploading file to existing release...")
          
          # Check if file with same name already exists in release
          release_assets_result = run_command!(
            command: ['gh', 'release', 'view', version, '--repo', repo, '--json', 'assets', '-q', '.assets[].name'],
            timeout_seconds: DEFAULT_GH_COMMAND_TIMEOUT_SECONDS,
            error_context: "Failed to inspect assets for release #{version}",
          )
          release_assets = release_assets_result[:stdout]
          file_name = File.basename(file_path)
          if release_assets.include?(file_name)
            UI.message("File #{file_name} already exists in release. Will overwrite with --clobber flag.")
          end
          
          # Upload file to existing release (--clobber will overwrite if file exists)
          upload_asset_with_retry(
            repo: repo,
            version: version,
            file_path: file_path,
            upload_retry_count: upload_retry_count,
            upload_timeout_seconds: upload_timeout_seconds,
          )
        else
          # Release doesn't exist, check if tag exists
          project_root = File.expand_path('../..', __dir__)
          
          # Clean up any incorrect tags that contain '+' (e.g., "3.4.0+612")
          # These should not exist - tag name should only be semantic version
          UI.message("Checking for incorrect tags containing '+' symbol...")
          incorrect_local_tags = `cd #{project_root} && git tag -l "*+*" 2>&1`.split("\n").select { |t| t.strip == full_version }
          incorrect_local_tags.each do |incorrect_tag|
            UI.important("Found incorrect local tag: #{incorrect_tag}. Deleting...")
            sh("cd #{project_root} && git tag -d #{incorrect_tag} 2>&1")
          end
          
          # Check for incorrect remote tags
          incorrect_remote_tag_check = run_command(
            command: ['gh', 'api', "repos/#{repo}/git/refs/tags/#{full_version}"],
            timeout_seconds: DEFAULT_GH_COMMAND_TIMEOUT_SECONDS,
          )
          if incorrect_remote_tag_check[:success]
            UI.important("Found incorrect remote tag: #{full_version}. Deleting...")
            run_command!(
              command: ['gh', 'api', "repos/#{repo}/git/refs/tags/#{full_version}", '-X', 'DELETE'],
              timeout_seconds: DEFAULT_GH_COMMAND_TIMEOUT_SECONDS,
              error_context: "Failed to delete incorrect remote tag #{full_version}",
            )
            UI.success("Deleted incorrect remote tag: #{full_version}")
          elsif !not_found_result?(incorrect_remote_tag_check)
            UI.user_error!("Failed to inspect remote tag #{full_version}: #{format_command_error(incorrect_remote_tag_check)}")
          end

          # Check if tag exists locally
          local_tag_check = `cd #{project_root} && git tag -l #{version} 2>&1`
          local_tag_exists = local_tag_check.strip == version

          # Check if tag exists on remote (using semantic version as tag name)
          tag_check = run_command(
            command: ['gh', 'api', "repos/#{repo}/git/refs/tags/#{version}"],
            timeout_seconds: DEFAULT_GH_COMMAND_TIMEOUT_SECONDS,
          )
          if tag_check[:success]
            remote_tag_exists = true
          elsif not_found_result?(tag_check)
            remote_tag_exists = false
          else
            UI.user_error!("Failed to inspect remote tag #{version}: #{format_command_error(tag_check)}")
          end

          if remote_tag_exists
            UI.message("Tag #{version} already exists on remote. Release does not exist. Creating release from existing tag...")
            
            # Get the commit SHA that the tag points to
            tag_ref_result = run_command!(
              command: ['gh', 'api', "repos/#{repo}/git/refs/tags/#{version}"],
              timeout_seconds: DEFAULT_GH_COMMAND_TIMEOUT_SECONDS,
              error_context: "Failed to get tag #{version} from repository #{repo}",
            )
            tag_ref = tag_ref_result[:stdout]
            tag_commit_sha = tag_ref.match(/"sha":"([^"]+)"/)
            if tag_commit_sha.nil?
              UI.user_error!("Failed to get commit SHA from tag #{version}")
            end
            tag_commit_sha = tag_commit_sha[1]
            
            # Ensure local tag exists too (for consistency)
            unless local_tag_exists
              UI.message("Creating local tag #{version} to match remote...")
              tag_create_result = sh("cd #{project_root} && git tag #{version} #{tag_commit_sha}")
              UI.success("Created local tag #{version}")
            end
            
            # Create release from existing tag
            run_command!(
              command: ['gh', 'release', 'create', version, '--repo', repo, '--title', release_name, '--notes', release_notes, '--target', tag_commit_sha],
              timeout_seconds: DEFAULT_GH_CREATE_TIMEOUT_SECONDS,
              error_context: "Failed to create release #{version} from existing tag",
            )
            UI.success("Successfully created release #{version} from existing tag")
          else
            UI.message("Tag #{version} does not exist. Creating tag and release...")
            
            # Get the latest commit from the branch
            branch_ref_result = run_command!(
              command: ['gh', 'api', "repos/#{repo}/git/refs/heads/#{branch}"],
              timeout_seconds: DEFAULT_GH_COMMAND_TIMEOUT_SECONDS,
              error_context: "Failed to get branch #{branch} from repository #{repo}",
            )
            branch_ref = branch_ref_result[:stdout]
            
            commit_sha = branch_ref.match(/"sha":"([^"]+)"/)
            if commit_sha.nil?
              UI.user_error!("Failed to get commit SHA from branch #{branch}")
            end
            commit_sha = commit_sha[1]

            UI.message("Creating tag #{version} on branch #{branch} (commit: #{commit_sha[0..7]})...")
            
            # Create tag in local git repository first (if it doesn't exist)
            unless local_tag_exists
              UI.message("Creating local tag #{version}...")
              tag_create_result = sh("cd #{project_root} && git tag #{version} #{commit_sha}")
              UI.success("Created local tag #{version}")
            else
              UI.message("Local tag #{version} already exists")
            end
            
            # Push tag to remote
            UI.message("Pushing tag #{version} to remote...")
            tag_push_result = sh("cd #{project_root} && git push origin #{version} 2>&1")
            unless $?.success?
              # If push fails, try to create via API as fallback
              tag_check_retry = run_command(
                command: ['gh', 'api', "repos/#{repo}/git/refs/tags/#{version}"],
                timeout_seconds: DEFAULT_GH_COMMAND_TIMEOUT_SECONDS,
              )
              if tag_check_retry[:success]
                UI.message("Tag #{version} already exists on remote (push was not needed)")
              elsif not_found_result?(tag_check_retry)
                UI.message("Git push failed, creating tag via GitHub API...")
                run_command!(
                  command: ['gh', 'api', "repos/#{repo}/git/refs", '-X', 'POST', '-f', "ref=refs/tags/#{version}", '-f', "sha=#{commit_sha}"],
                  timeout_seconds: DEFAULT_GH_COMMAND_TIMEOUT_SECONDS,
                  error_context: "Failed to create remote tag #{version} via GitHub API",
                )
                UI.success("Created tag #{version} via GitHub API")
              else
                UI.user_error!("Git push failed and remote tag check also failed: #{format_command_error(tag_check_retry)}")
              end
            else
              UI.success("Pushed tag #{version} to remote")
            end
            
            # Create release from the new tag
            UI.message("Creating release #{version} from new tag...")
            run_command!(
              command: ['gh', 'release', 'create', version, '--repo', repo, '--title', release_name, '--notes', release_notes, '--target', commit_sha],
              timeout_seconds: DEFAULT_GH_CREATE_TIMEOUT_SECONDS,
              error_context: "Failed to create release #{version} from new tag",
            )
            UI.success("Successfully created release #{version}")
          end

          # Upload file to the release (whether it was just created or already existed)
          upload_asset_with_retry(
            repo: repo,
            version: version,
            file_path: file_path,
            upload_retry_count: upload_retry_count,
            upload_timeout_seconds: upload_timeout_seconds,
          )
        end

        UI.success("Release URL: https://github.com/#{repo}/releases/tag/#{version}")
      end

      def self.upload_asset_with_retry(repo:, version:, file_path:, upload_retry_count:, upload_timeout_seconds:)
        file_name = File.basename(file_path)
        attempt = 1

        loop do
          UI.message("Uploading #{file_name} to release #{version} (attempt #{attempt}/#{upload_retry_count}, timeout #{upload_timeout_seconds}s)...")
          result = run_command(
            command: ['gh', 'release', 'upload', version, file_path, '--repo', repo, '--clobber'],
            timeout_seconds: upload_timeout_seconds,
          )
          if result[:success]
            UI.success("Successfully uploaded #{file_name} to release #{version}")
            return
          end

          error_message = format_command_error(result)
          retryable = retryable_upload_error?(error_message)
          if !retryable || attempt >= upload_retry_count
            UI.user_error!("Failed to upload #{file_name} to release #{version}: #{error_message}")
          end

          wait_seconds = [attempt * 3, 30].min
          UI.important("Upload failed (attempt #{attempt}/#{upload_retry_count}): #{error_message}")
          UI.message("Retrying in #{wait_seconds}s...")
          sleep(wait_seconds)
          attempt += 1
        end
      end

      def self.retryable_upload_error?(error_message)
        normalized = error_message.to_s.downcase
        return true if normalized.include?('timed out after')
        return true if normalized.include?('eof')
        return true if normalized.include?('timed out')
        return true if normalized.include?('timeout')
        return true if normalized.include?('tls handshake timeout')
        return true if normalized.include?('context deadline exceeded')
        return true if normalized.include?('connection reset')
        return true if normalized.include?('connection refused')
        return true if normalized.include?('network is unreachable')
        return true if normalized.include?('http 408')
        return true if normalized.include?('http 429')
        return true if normalized.include?('502')
        return true if normalized.include?('503')
        return true if normalized.include?('504')
        false
      end

      def self.run_command(command:, timeout_seconds:, cwd: nil)
        stdout = +''
        stderr = +''
        status = nil
        timed_out = false
        env = {
          'GH_PROMPT_DISABLED' => '1',
          'NO_COLOR' => '1',
        }

        Open3.popen3(env, *command, chdir: cwd, pgroup: true) do |stdin, out, err, wait_thr|
          stdin.close

          stdout_thread = Thread.new do
            stdout = out.read.to_s
          end
          stderr_thread = Thread.new do
            stderr = err.read.to_s
          end

          begin
            Timeout.timeout(timeout_seconds) do
              status = wait_thr.value
            end
          rescue Timeout::Error
            timed_out = true
            terminate_process_group(wait_thr.pid)
            begin
              status = wait_thr.value
            rescue StandardError
              status = nil
            end
          ensure
            stdout_thread.join
            stderr_thread.join
          end
        end

        {
          stdout: stdout,
          stderr: stderr,
          status: status,
          success: !timed_out && status&.success?,
          timed_out: timed_out,
          timeout_seconds: timeout_seconds,
        }
      rescue StandardError => e
        {
          stdout: stdout,
          stderr: [stderr, e.message].reject(&:empty?).join("\n"),
          status: nil,
          success: false,
          timed_out: false,
          timeout_seconds: timeout_seconds,
        }
      end

      def self.run_command!(command:, timeout_seconds:, error_context:, cwd: nil)
        result = run_command(
          command: command,
          timeout_seconds: timeout_seconds,
          cwd: cwd,
        )
        if result[:success]
          return result
        end

        UI.user_error!("#{error_context}: #{format_command_error(result)}")
      end

      def self.format_command_error(result)
        if result[:timed_out]
          return "timed out after #{result[:timeout_seconds]}s"
        end

        combined_output = [result[:stderr], result[:stdout]].reject(&:nil?).join("\n").strip
        if !combined_output.empty?
          return combined_output.lines.first.to_s.strip
        end

        exit_code = result[:status]&.exitstatus
        return "exited with status #{exit_code}" unless exit_code.nil?

        'unknown command failure'
      end

      def self.not_found_result?(result)
        return false if result[:success]
        return false if result[:timed_out]

        combined_output = [result[:stderr], result[:stdout]].reject(&:nil?).join("\n").downcase
        return true if combined_output.include?('release not found')
        return true if combined_output.include?('not found')
        return true if combined_output.include?('http 404')
        false
      end

      def self.terminate_process_group(pid)
        begin
          Process.kill('TERM', -pid)
        rescue Errno::ESRCH
        end

        sleep(2)

        begin
          Process.kill('KILL', -pid)
        rescue Errno::ESRCH
        end
      end

      def self.description
        "Check for GitHub release, create if not exists, and upload file"
      end

      def self.authors
        ["rwkv_app"]
      end

      def self.return_value
        "Returns the release URL"
      end

      def self.details
        "Check if a GitHub release exists for the given version. If not, create it from the specified branch and upload the file."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repo,
                                       env_name: "GITHUB_REPO",
                                       description: "GitHub repository (e.g., 'RWKV-APP/RWKV_APP')",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :version,
                                       env_name: "GITHUB_RELEASE_VERSION",
                                       description: "Release version (tag name)",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :file_path,
                                       env_name: "GITHUB_RELEASE_FILE",
                                       description: "Path to the file to upload",
                                       optional: false,
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :branch,
                                       env_name: "GITHUB_RELEASE_BRANCH",
                                       description: "Branch to create tag from (default: 'dev')",
                                       optional: true,
                                       default_value: "dev",
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :release_name,
                                       env_name: "GITHUB_RELEASE_NAME",
                                       description: "Release name (defaults to version)",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :release_notes,
                                       env_name: "GITHUB_RELEASE_NOTES",
                                       description: "Release notes",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :upload_retry_count,
                                       env_name: "GITHUB_RELEASE_UPLOAD_RETRY_COUNT",
                                       description: "How many times to retry `gh release upload` on transient network failures",
                                       optional: true,
                                       default_value: 3,
                                       verify_block: proc do |value|
                                         UI.user_error!("upload_retry_count must be >= 1") if value.to_i < 1
                                       end,
                                       type: Integer),
          FastlaneCore::ConfigItem.new(key: :upload_timeout_seconds,
                                       env_name: "GITHUB_RELEASE_UPLOAD_TIMEOUT_SECONDS",
                                       description: "Per-attempt timeout for `gh release upload` in seconds",
                                       optional: true,
                                       default_value: DEFAULT_UPLOAD_TIMEOUT_SECONDS,
                                       verify_block: proc do |value|
                                         UI.user_error!("upload_timeout_seconds must be >= 30") if value.to_i < 30
                                       end,
                                       type: Integer),
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac, :android].include?(platform)
      end
    end
  end
end
