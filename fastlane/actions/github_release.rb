require 'shellwords'

module Fastlane
  module Actions
    class GithubReleaseAction < Action
      def self.run(params)
        UI.message("The github_release plugin is working.")

        repo = params[:repo]
        full_version = params[:version]
        file_path = params[:file_path]
        branch = params[:branch] || "dev"
        release_name = params[:release_name] || full_version
        release_notes = params[:release_notes] || "Release #{full_version}"
        upload_retry_count = (params[:upload_retry_count] || 3).to_i
        if upload_retry_count < 1
          UI.user_error!("upload_retry_count must be >= 1")
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
        auth_status = `gh auth status 2>&1`
        unless $?.success?
          UI.user_error!("You are not authenticated with GitHub CLI. Please run: gh auth login")
        end

        UI.message("Checking for existing release: #{version} (tag) in #{repo}")

        # Check if release exists (using semantic version as tag name)
        release_check = `gh release view #{version} --repo #{repo} 2>&1`
        release_exists = $?.success?

        if release_exists
          UI.message("Release #{version} already exists. Uploading file to existing release...")
          
          # Check if file with same name already exists in release
          release_assets = `gh release view #{version} --repo #{repo} --json assets -q '.assets[].name' 2>&1`
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
          incorrect_remote_tag_check = `gh api repos/#{repo}/git/refs/tags/#{full_version} 2>&1`
          if $?.success?
            UI.important("Found incorrect remote tag: #{full_version}. Deleting...")
            sh("gh api repos/#{repo}/git/refs/tags/#{full_version} -X DELETE 2>&1")
            UI.success("Deleted incorrect remote tag: #{full_version}")
          end

          # Check if tag exists locally
          local_tag_check = `cd #{project_root} && git tag -l #{version} 2>&1`
          local_tag_exists = local_tag_check.strip == version

          # Check if tag exists on remote (using semantic version as tag name)
          tag_check = `gh api repos/#{repo}/git/refs/tags/#{version} 2>&1`
          remote_tag_exists = $?.success?

          if remote_tag_exists
            UI.message("Tag #{version} already exists on remote. Release does not exist. Creating release from existing tag...")
            
            # Get the commit SHA that the tag points to
            tag_ref = `gh api repos/#{repo}/git/refs/tags/#{version} 2>&1`
            unless $?.success?
              UI.user_error!("Failed to get tag #{version} from repository #{repo}")
            end
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
            release_result = sh("gh release create #{version} --repo #{repo} --title '#{release_name}' --notes '#{release_notes}' --target #{tag_commit_sha}")
            UI.success("Successfully created release #{version} from existing tag")
          else
            UI.message("Tag #{version} does not exist. Creating tag and release...")
            
            # Get the latest commit from the branch
            branch_ref = `gh api repos/#{repo}/git/refs/heads/#{branch} 2>&1`
            unless $?.success?
              UI.user_error!("Failed to get branch #{branch} from repository #{repo}")
            end
            
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
              tag_check_retry = `gh api repos/#{repo}/git/refs/tags/#{version} 2>&1`
              unless $?.success?
                UI.message("Git push failed, creating tag via GitHub API...")
                tag_result = sh("gh api repos/#{repo}/git/refs -X POST -f ref=refs/tags/#{version} -f sha=#{commit_sha}")
                UI.success("Created tag #{version} via GitHub API")
              else
                UI.message("Tag #{version} already exists on remote (push was not needed)")
              end
            else
              UI.success("Pushed tag #{version} to remote")
            end
            
            # Create release from the new tag
            UI.message("Creating release #{version} from new tag...")
            release_result = sh("gh release create #{version} --repo #{repo} --title '#{release_name}' --notes '#{release_notes}' --target #{commit_sha}")
            UI.success("Successfully created release #{version}")
          end

          # Upload file to the release (whether it was just created or already existed)
          upload_asset_with_retry(
            repo: repo,
            version: version,
            file_path: file_path,
            upload_retry_count: upload_retry_count,
          )
        end

        UI.success("Release URL: https://github.com/#{repo}/releases/tag/#{version}")
      end

      def self.upload_asset_with_retry(repo:, version:, file_path:, upload_retry_count:)
        file_name = File.basename(file_path)
        attempt = 1
        escaped_version = Shellwords.escape(version)
        escaped_file_path = Shellwords.escape(file_path)
        escaped_repo = Shellwords.escape(repo)

        loop do
          begin
            sh("gh release upload #{escaped_version} #{escaped_file_path} --repo #{escaped_repo} --clobber")
            UI.success("Successfully uploaded #{file_name} to release #{version}")
            return
          rescue => e
            error_message = e.message.to_s
            retryable = retryable_upload_error?(error_message)
            first_line = error_message.split("\n").first.to_s.strip
            if !retryable || attempt >= upload_retry_count
              UI.user_error!("Failed to upload #{file_name} to release #{version}: #{first_line}")
            end
            wait_seconds = attempt * 3
            UI.important("Upload failed (attempt #{attempt}/#{upload_retry_count}): #{first_line}")
            UI.message("Retrying in #{wait_seconds}s...")
            sleep(wait_seconds)
            attempt += 1
          end
        end
      end

      def self.retryable_upload_error?(error_message)
        normalized = error_message.to_s.downcase
        return true if normalized.include?('eof')
        return true if normalized.include?('timed out')
        return true if normalized.include?('timeout')
        return true if normalized.include?('connection reset')
        return true if normalized.include?('connection refused')
        return true if normalized.include?('network is unreachable')
        return true if normalized.include?('502')
        return true if normalized.include?('503')
        return true if normalized.include?('504')
        false
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
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac, :android].include?(platform)
      end
    end
  end
end
