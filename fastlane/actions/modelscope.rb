require 'shellwords'

module Fastlane
  module Actions
    class ModelscopeAction < Action
      def self.run(params)
        repo_id = params[:repo_id]
        file_path = File.expand_path(params[:file_path])
        path_in_repo = params[:path_in_repo] || File.basename(file_path)
        token = params[:token] || ENV['MODELSCOPE_API_TOKEN']
        endpoint = params[:endpoint] || ENV['MODELSCOPE_ENDPOINT'] || 'https://modelscope.cn'
        revision = params[:revision] || ENV['MODELSCOPE_REVISION'] || 'master'
        commit_message = params[:commit_message] || "Upload #{File.basename(file_path)}"

        UI.user_error!('MODELSCOPE_API_TOKEN is required') if token.nil? || token.empty?
        UI.user_error!("File not found: #{file_path}") unless File.file?(file_path)

        project_root = File.expand_path('../..', __dir__)
        upload_script = File.join(project_root, 'scripts', 'upload_to_modelscope.py')
        UI.user_error!("Upload script not found: #{upload_script}") unless File.file?(upload_script)

        unless system("python3 -c 'import modelscope_hub' 2>/dev/null")
          UI.important('Installing modelscope-hub...')
          installed = system('pip3 install --break-system-packages modelscope-hub 2>/dev/null') ||
                      system('pip3 install --user modelscope-hub 2>/dev/null') ||
                      system('pip3 install modelscope-hub 2>/dev/null')
          UI.user_error!('Failed to install modelscope-hub') unless installed
        end

        command = [
          'python3',
          Shellwords.escape(upload_script),
          '--repo-id', Shellwords.escape(repo_id),
          '--file', Shellwords.escape(file_path),
          '--path-in-repo', Shellwords.escape(path_in_repo),
          '--endpoint', Shellwords.escape(endpoint),
          '--revision', Shellwords.escape(revision),
          '--commit-message', Shellwords.escape(commit_message),
        ].join(' ')

        previous_token = ENV['MODELSCOPE_API_TOKEN']
        ENV['MODELSCOPE_API_TOKEN'] = token
        begin
          sh(command)
        ensure
          if previous_token.nil?
            ENV.delete('MODELSCOPE_API_TOKEN')
          else
            ENV['MODELSCOPE_API_TOKEN'] = previous_token
          end
        end

        UI.success("ModelScope upload completed: #{repo_id}/#{path_in_repo}")
      end

      def self.description
        'Upload an RWKV App artifact to a ModelScope dataset repository'
      end

      def self.authors
        ['rwkv_app']
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repo_id,
                                       env_name: 'MODELSCOPE_REPO_ID',
                                       description: 'ModelScope dataset repository ID',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :file_path,
                                       description: 'Path to the artifact to upload',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :path_in_repo,
                                       description: 'Destination path in the dataset repository',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :token,
                                       env_name: 'MODELSCOPE_API_TOKEN',
                                       description: 'ModelScope API token',
                                       optional: true,
                                       sensitive: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :endpoint,
                                       env_name: 'MODELSCOPE_ENDPOINT',
                                       description: 'ModelScope endpoint',
                                       optional: true,
                                       default_value: 'https://modelscope.cn',
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :revision,
                                       env_name: 'MODELSCOPE_REVISION',
                                       description: 'Target dataset branch',
                                       optional: true,
                                       default_value: 'master',
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :commit_message,
                                       description: 'ModelScope commit message',
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
