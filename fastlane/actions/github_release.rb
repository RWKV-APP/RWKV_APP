module Fastlane
  module Actions
    class GithubReleaseAction < Action
      def self.run(params)
        UI.message("The github_release plugin is working.")

        repo = params[:repo]
        version = params[:version]
        file_path = params[:file_path]
        branch = params[:branch] || "dev"
        release_name = params[:release_name] || version
        release_notes = params[:release_notes] || "Release #{version}"

        if repo.nil? || repo.empty?
          UI.user_error!("You have to provide a repo (e.g., 'RWKV-APP/RWKV_APP')")
        end

        if version.nil? || version.empty?
          UI.user_error!("You have to provide a version")
        end

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

        UI.message("Checking for existing release: #{version} in #{repo}")

        # Check if release exists
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
          upload_result = sh("gh release upload #{version} '#{file_path}' --repo #{repo} --clobber")
          UI.success("Successfully uploaded #{file_name} to release #{version}")
        else
          UI.message("Release #{version} does not exist. Creating new release...")
          
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

          UI.message("Creating release #{version} from branch #{branch} (commit: #{commit_sha[0..7]})...")

          # Check if tag exists
          tag_check = `gh api repos/#{repo}/git/refs/tags/#{version} 2>&1`
          tag_exists = $?.success?

          if tag_exists
            UI.message("Tag #{version} already exists. Using existing tag...")
            # Create release from existing tag
            release_result = sh("gh release create #{version} --repo #{repo} --title '#{release_name}' --notes '#{release_notes}' --target #{version}")
          else
            UI.message("Creating tag #{version} on branch #{branch}...")
            # Create tag first
            tag_result = sh("gh api repos/#{repo}/git/refs -X POST -f ref=refs/tags/#{version} -f sha=#{commit_sha}")
            # Create release from the new tag
            release_result = sh("gh release create #{version} --repo #{repo} --title '#{release_name}' --notes '#{release_notes}' --target #{version}")
          end

          UI.success("Successfully created release #{version}")

          # Upload file to the new release
          upload_result = sh("gh release upload #{version} '#{file_path}' --repo #{repo}")
          UI.success("Successfully uploaded #{File.basename(file_path)} to release #{version}")
        end

        UI.success("Release URL: https://github.com/#{repo}/releases/tag/#{version}")
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
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac, :android].include?(platform)
      end
    end
  end
end

