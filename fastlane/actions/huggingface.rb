module Fastlane
  module Actions
    class HuggingfaceAction < Action
      def self.run(params)
        UI.message("The huggingface plugin is working.")

        repo_id = params[:repo_id]
        file_path = params[:file_path]
        token = params[:token] || ENV['HF_TOKEN']
        path_in_repo = params[:path_in_repo] || File.basename(file_path)
        commit_message = params[:commit_message] || "Upload #{File.basename(file_path)}"
        repo_type = params[:repo_type] || "dataset"

        if repo_id.nil? || repo_id.empty?
          UI.user_error!("You have to provide a repo_id (e.g., 'username/repo-name')")
        end

        if file_path.nil? || !File.exist?(file_path)
          UI.user_error!("File not found at path: #{file_path}")
        end

        if token.nil? || token.empty?
          UI.user_error!("You have to provide a Hugging Face token via :token parameter or HF_TOKEN environment variable")
        end

        UI.message("Uploading #{file_path} to Hugging Face repository: #{repo_id} (type: #{repo_type})")
        UI.message("Path in repo: #{path_in_repo}")

        # Check if huggingface_hub is installed, install if missing
        unless system("python3 -c 'import huggingface_hub' 2>/dev/null")
          UI.important("huggingface_hub is not installed. Installing it now...")
          # Try multiple installation methods
          installed = false
          
          # Try pip3 with --break-system-packages (for externally-managed environments)
          if system("pip3 install --break-system-packages huggingface_hub 2>/dev/null")
            installed = true
          # Try pip3 with --user flag
          elsif system("pip3 install --user huggingface_hub 2>/dev/null")
            installed = true
          # Try pip3 without flags
          elsif system("pip3 install huggingface_hub 2>/dev/null")
            installed = true
          # Try pip with --break-system-packages
          elsif system("pip install --break-system-packages huggingface_hub 2>/dev/null")
            installed = true
          # Try pip with --user flag
          elsif system("pip install --user huggingface_hub 2>/dev/null")
            installed = true
          # Try pip without flags
          elsif system("pip install huggingface_hub 2>/dev/null")
            installed = true
          end
          
          if installed
            UI.success("Successfully installed huggingface_hub")
          else
            UI.user_error!("Failed to install huggingface_hub. Please install it manually with: pip install --break-system-packages huggingface_hub")
          end
        end

        # Get absolute path to ensure Python script can find the file
        absolute_file_path = File.expand_path(file_path)

        # Create a Python script to upload the file
        script = <<~PYTHON
          from huggingface_hub import HfApi, login
          import sys
          import os
          
          # Clear proxy environment variables to avoid SOCKS proxy issues
          proxy_vars = ['HTTP_PROXY', 'HTTPS_PROXY', 'http_proxy', 'https_proxy', 
                       'ALL_PROXY', 'all_proxy', 'SOCKS_PROXY', 'socks_proxy']
          for var in proxy_vars:
              if var in os.environ:
                  del os.environ[var]
          
          repo_id = "#{repo_id}"
          file_path = "#{absolute_file_path}"
          path_in_repo = "#{path_in_repo}"
          token = "#{token}"
          commit_message = "#{commit_message}"
          repo_type = "#{repo_type}"
          
          try:
              login(token=token)
              api = HfApi()
              api.upload_file(
                  path_or_fileobj=file_path,
                  path_in_repo=path_in_repo,
                  repo_id=repo_id,
                  repo_type=repo_type,
                  commit_message=commit_message
              )
              print(f"Successfully uploaded {file_path} to {repo_id}/{path_in_repo}")
          except Exception as e:
              print(f"Error: {e}", file=sys.stderr)
              sys.exit(1)
        PYTHON

        # Write script to temporary file
        script_file = File.join(Dir.tmpdir, "huggingface_upload_#{Time.now.to_i}.py")
        File.write(script_file, script)

        begin
          # Execute the Python script
          result = sh("python3 #{script_file}")
          UI.success("Successfully uploaded to Hugging Face!")
          UI.success("Repository: https://huggingface.co/datasets/#{repo_id}") if repo_type == "dataset"
          UI.success("Repository: https://huggingface.co/#{repo_id}") if repo_type == "model"
          UI.success("File: https://huggingface.co/datasets/#{repo_id}/resolve/main/#{path_in_repo}") if repo_type == "dataset"
          UI.success("File: https://huggingface.co/#{repo_id}/resolve/main/#{path_in_repo}") if repo_type == "model"
          result
        rescue => e
          UI.user_error!("Failed to upload to Hugging Face: #{e.message}")
        ensure
          # Clean up temporary script file
          File.delete(script_file) if File.exist?(script_file)
        end
      end

      def self.description
        "Upload file to Hugging Face repository"
      end

      def self.authors
        ["rwkv_app"]
      end

      def self.return_value
        "Returns the upload result"
      end

      def self.details
        "Upload a file (APK, IPA, etc.) to a specified Hugging Face repository"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repo_id,
                                       env_name: "HF_DATASETS_ID",
                                       description: "Hugging Face repository ID (e.g., 'username/repo-name')",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :file_path,
                                       env_name: "HF_FILE_PATH",
                                       description: "Path to the file to upload",
                                       optional: false,
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :token,
                                       env_name: "HF_TOKEN",
                                       description: "Hugging Face access token",
                                       optional: true,
                                       sensitive: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :path_in_repo,
                                       env_name: "HF_PATH_IN_REPO",
                                       description: "Path in the repository (defaults to filename)",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :commit_message,
                                       env_name: "HF_COMMIT_MESSAGE",
                                       description: "Commit message for the upload",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :repo_type,
                                       env_name: "HF_REPO_TYPE",
                                       description: "Repository type: 'model' or 'dataset' (default: 'dataset')",
                                       optional: true,
                                       default_value: "dataset",
                                       type: String),
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac, :android].include?(platform)
      end
    end
  end
end

