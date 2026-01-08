module Fastlane
  module Actions
    class HuggingfaceAction < Action
      def self.run(params)
        UI.message('The huggingface plugin is working.')

        repo_id = params[:repo_id]
        file_path = params[:file_path]
        token = params[:token] || ENV['HF_TOKEN']
        path_in_repo = params[:path_in_repo] || File.basename(file_path)
        commit_message = params[:commit_message] || "Upload #{File.basename(file_path)}"
        repo_type = params[:repo_type] || 'dataset'

        if repo_id.nil? || repo_id.empty?
          UI.user_error!("You have to provide a repo_id (e.g., 'username/repo-name')")
        end

        if file_path.nil? || !File.exist?(file_path)
          UI.user_error!("File not found at path: #{file_path}")
        end

        if token.nil? || token.empty?
          UI.user_error!('You have to provide a Hugging Face token via :token parameter or HF_TOKEN environment variable')
        end

        UI.message("Uploading #{file_path} to Hugging Face repository: #{repo_id} (type: #{repo_type})")
        UI.message("Path in repo: #{path_in_repo}")

        # --- 依赖检查与安装 ---
        packages_to_install = []
        packages_to_install << 'huggingface_hub' unless system("python3 -c 'import huggingface_hub' 2>/dev/null")
        packages_to_install << 'hf_transfer' unless system("python3 -c 'import hf_transfer' 2>/dev/null")

        unless packages_to_install.empty?
          UI.important("Installing missing packages: #{packages_to_install.join(', ')}...")
          packages_to_install.each do |pkg|
            # 优先使用 --break-system-packages 适配现代 Python 环境
            unless system("pip3 install --break-system-packages #{pkg} 2>/dev/null") ||
                   system("pip3 install --user #{pkg} 2>/dev/null") ||
                   system("pip3 install #{pkg} 2>/dev/null")
              UI.user_error!("Failed to install #{pkg}. Please run: pip3 install --break-system-packages #{pkg}")
            end
          end
          UI.success('Successfully installed dependencies')
        end

        # 获取绝对路径
        absolute_file_path = File.expand_path(file_path)

        # --- 优化后的 Python 脚本 ---
        script = <<~PYTHON
          from huggingface_hub import HfApi, login
          import sys
          import os
          import time

          # 启用 hf_transfer 加速
          os.environ["HF_HUB_ENABLE_HF_TRANSFER"] = "1"
          
          repo_id = "#{repo_id}"
          file_path = "#{absolute_file_path}"
          path_in_repo = "#{path_in_repo}"
          token = "#{token}"
          commit_message = "#{commit_message}"
          repo_type = "#{repo_type}"
          
          max_retries = 3
          success = False

          for attempt in range(max_retries):
              try:
                  if attempt > 0:
                      print(f"Retrying upload (Attempt {attempt + 1}/{max_retries})...")
                  
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
                  success = True
                  break
              except Exception as e:
                  print(f"Error on attempt {attempt + 1}: {e}", file=sys.stderr)
                  if attempt < max_retries - 1:
                      time.sleep(10) # 失败后等待 10 秒重试
                  else:
                      print("All upload attempts failed.", file=sys.stderr)

          if not success:
              sys.exit(1)
        PYTHON

        # 写入临时脚本
        script_file = File.join(Dir.tmpdir, "huggingface_upload_#{Time.now.to_i}.py")
        File.write(script_file, script)

        begin
          # 执行 Python 脚本
          sh("python3 #{script_file}")
          UI.success('Successfully uploaded to Hugging Face!')

          # 打印链接
          base_url = "https://huggingface.co/#{repo_type == 'dataset' ? 'datasets/' : ''}#{repo_id}"
          UI.success("Repository: #{base_url}")
          UI.success("File: #{base_url}/resolve/main/#{path_in_repo}")
        rescue => e
          UI.user_error!("Failed to upload to Hugging Face after retries: #{e.message}")
        ensure
          File.delete(script_file) if File.exist?(script_file)
        end
      end

      def self.description
        'Upload file to Hugging Face repository with hf_transfer support'
      end

      def self.authors
        ['rwkv_app']
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repo_id,
                                       env_name: 'HF_DATASETS_ID',
                                       description: 'Hugging Face repository ID',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :file_path,
                                       env_name: 'HF_FILE_PATH',
                                       description: 'Path to the file to upload',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :token,
                                       env_name: 'HF_TOKEN',
                                       description: 'Hugging Face access token',
                                       optional: true,
                                       sensitive: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :path_in_repo,
                                       env_name: 'HF_PATH_IN_REPO',
                                       description: 'Path in the repository',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :commit_message,
                                       env_name: 'HF_COMMIT_MESSAGE',
                                       description: 'Commit message',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :repo_type,
                                       env_name: 'HF_REPO_TYPE',
                                       description: "Repository type: 'model' or 'dataset'",
                                       optional: true,
                                       default_value: 'dataset',
                                       type: String),
        ]
      end

      def self.is_supported?(platform)
        [:ios, :mac, :android].include?(platform)
      end
    end
  end
end
