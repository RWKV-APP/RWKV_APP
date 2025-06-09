require "faraday"
require "faraday_middleware"

module Fastlane
  module Actions
    class PgyerAction < Action
      def self.run(params)
        UI.message("The pgyer plugin is working.")

        api_key = params[:api_key]

        build_file = params[:apk]

        if build_file.nil?
          UI.user_error!("You have to provide a build file")
        end

        type = "android"

        UI.message "build_file: #{build_file}, type: #{type}"

        install_type = params[:install_type]
        if install_type.nil?
          install_type = "1"
        end

        password = params[:password]
        if password.nil?
          password = ""
        end

        request_params = {
          "_api_key" => api_key,
          "buildType" => type,
          "buildInstallType" => install_type,
          "buildPassword" => password,
        }
        request_params["oversea"] = params[:oversea] unless params[:oversea].nil?

        update_description = params[:update_description]

        if update_description != nil
          request_params["buildUpdateDescription"] = update_description
        end

        install_date = params[:install_date]

        if install_date != nil
          if install_date == "1"
            request_params["buildInstallDate"] = install_date
            install_start_date = params[:install_start_date]
            request_params["buildInstallStartDate"] = install_start_date
            install_end_date = params[:install_end_date]
            request_params["buildInstallEndDate"] = install_end_date
          elsif install_date == "2"
            request_params["buildInstallDate"] = install_date
          end
        end

        channel = params[:channel]
        if channel != nil
          request_params["buildChannelShortcut"] = channel
        end

        # start upload
        conn_options = {
          request: {
            timeout: 1000,
            open_timeout: 300,
          },
        }

        api_host = "https://www.pgyer.com/apiv2/app"

        pgyer_client = Faraday.new(nil, conn_options) do |c|
          c.request :multipart
          c.request :url_encoded
          c.response :json, content_type: /\bjson$/
          c.adapter :net_http
        end

        response = pgyer_client.post "#{api_host}/getCOSToken", request_params

        info = response.body

        if info["code"] != 0
          UI.user_error!("Get token is failed, info: #{info}")
        end

        key = info["data"]["key"]

        endpoint = info["data"]["endpoint"]

        request_params = info["data"]["params"]

        if key.nil? || endpoint.nil? || request_params.nil?
          UI.user_error!("Get token is failed")
        end
        content_type = type == "android" ? "application/vnd.android.package-archive" : "application/octet-stream"

        if !params[:user_download_file_name].nil?
          request_params["x-cos-meta-file-name"] = params[:user_download_file_name]
        end
        request_params["file"] = Faraday::UploadIO.new(build_file, content_type)

        UI.message "Start upload #{build_file} to pgyer..."

        UI.message "Upload endpoint: #{endpoint}"

        UI.message "Upload request_params: #{request_params}"

        response = pgyer_client.post endpoint, request_params

        if response.status != 204
          UI.user_error!("PGYER Plugin Upload Error: #{response.body}")
        end

        answer = self.checkPublishStatus(pgyer_client, api_host, api_key, key)

        if params[:save_uploaded_info_json]
          File.open("pgyer-fastlane-uploaded-app-info.json", "w") do |f|
            f.write(answer.to_json)
          end
        end
        answer
      end

      def self.description
        "distribute app to pgyer beta testing service"
      end

      def self.authors
        ["rexshi"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "distribute app to pgyer beta testing service"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_key,
                                       env_name: "PGYER_API_KEY",
                                       description: "api_key in your pgyer account",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :apk,
                                       env_name: "PGYER_APK",
                                       description: "Path to your APK file",
                                       default_value: Actions.lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH],
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find apk file at path '#{value}'") unless File.exist?(value)
                                       end,
                                       conflicting_options: [:ipa],
                                       conflict_block: proc do |value|
                                         UI.user_error!("You can't use 'apk' and '#{value.key}' options in one run")
                                       end),
          FastlaneCore::ConfigItem.new(key: :ipa,
                                       env_name: "PGYER_IPA",
                                       description: "Path to your IPA file. Optional if you use the _gym_ or _xcodebuild_ action. For Mac zip the .app. For Android provide path to .apk file",
                                       default_value: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH],
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find ipa file at path '#{value}'") unless File.exist?(value)
                                       end,
                                       conflicting_options: [:apk],
                                       conflict_block: proc do |value|
                                         UI.user_error!("You can't use 'ipa' and '#{value.key}' options in one run")
                                       end),
          FastlaneCore::ConfigItem.new(key: :password,
                                       env_name: "PGYER_PASSWORD",
                                       description: "Set password to protect app",
                                       optional: true,
                                       type: String),

          FastlaneCore::ConfigItem.new(key: :user_download_file_name,
                                       env_name: "USER_DOWNLOAD_FILE_NAME",
                                       description: "Rename the file name that user downloaded from pgyer",
                                       optional: true,
                                       type: String),

          FastlaneCore::ConfigItem.new(key: :update_description,
                                       env_name: "PGYER_UPDATE_DESCRIPTION",
                                       description: "Set update description for app",
                                       optional: true,
                                       type: String),

          FastlaneCore::ConfigItem.new(key: :save_uploaded_info_json,
                                       env_name: "PGYER_SAVE_UPLOADED_INFO_JSON",
                                       description: "Save uploaded info json to file named pgyer-fastlane-uploaded-app-info.json",
                                       optional: true,
                                       default_value: false,
                                       type: Boolean),

          FastlaneCore::ConfigItem.new(key: :install_type,
                                       env_name: "PGYER_INSTALL_TYPE",
                                       description: "Set install type for app (1=public, 2=password, 3=invite). Please set as a string",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :install_date,
                                       env_name: "PGYER_INSTALL_DATE",
                                       description: "Set install type for app (1=Set valid time, 2=Long-term effective, other=Do not modify the last setting). Please set as a string",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :install_start_date,
                                       env_name: "PGYER_INSTALL_START_DATE",
                                       description: "The value is a string of characters, for example, 2018-01-01",
                                       optional: true,
                                       type: String),

          FastlaneCore::ConfigItem.new(key: :install_end_date,
                                       env_name: "PGYER_INSTALL_END_DATE",
                                       description: "The value is a string of characters, such as 2018-12-31",
                                       optional: true,
                                       type: String),

          FastlaneCore::ConfigItem.new(key: :oversea,
                                       env_name: "PGYER_OVERSEA",
                                       description: "Whether to use overseas acceleration. 1 for overseas accelerated upload, 0 for domestic accelerated upload, not filled in for automatic judgment based on IP",
                                       optional: true,
                                       type: Numeric),
          FastlaneCore::ConfigItem.new(key: :channel,
                                       env_name: "PGYER_SPECIFIED_CHANNEL",
                                       description: "Need to update the specified channel of the download short link, can specify only one channel, string type, such as: ABCD",
                                       optional: true,
                                       type: String),
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://github.com/fastlane/fastlane/blob/master/fastlane/docs/Platforms.md
        #
        [:ios, :mac, :android].include?(platform)
        true
      end

      private

      def self.checkPublishStatus(client, api_host, api_key, buildKey)
        url = "#{api_host}/buildInfo"
        UI.message "checkPublishStatus url: #{url}"
        response = client.post "#{api_host}/buildInfo", { :_api_key => api_key, :buildKey => buildKey }
        info = response.body
        code = info["code"]
        if code == 0
          UI.success "Upload success. BuildInfo is #{info["data"]}."
          shortUrl = info["data"]["buildShortcutUrl"]
          if shortUrl.nil? || shortUrl == ""
            shortUrl = info["data"]["buildKey"]
          end
          info["data"]["fastlaneAddedWholeVisitUrl"] = "https://www.pgyer.com/#{shortUrl}"
          UI.success "Upload success. Visit this URL to see: #{info["data"]["fastlaneAddedWholeVisitUrl"]}"
          return info["data"]
        elsif code == 1246 || code == 1247
          sleep 3
          self.checkPublishStatus(client, api_host, api_key, buildKey)
        else
          UI.user_error!("PGYER Plugin Published Error: #{info} buildKey: #{buildKey}")
        end
      end
    end
  end
end
