# @deprecated
module InvestCooker
  module YICAI
    class Client
      def initialize
        @soap = Savon.client { wsdl Settings.yicai.wsdl }
      end

      def download_zip(option={})
        @option = option
        parse_time
        hash = @soap.call(:get_zip_file_data, message: message ).body
        data = hash.find_by_key(:file_path_data).first
        data = Base64.decode64(data)
        @file_name = "#{TIME_ZONE.call.now.to_f}.zip"
        File.open(zip_file, 'wb+') { |f| f.puts data }
        ::YICAI::ExtractZipJob.perform_later(zip_file)
      rescue
        puts hash.find_by_key(:error_message).first
      end

      private

      def zip_file
        File.expand_path @file_name, File.expand_path(Settings.yicai.zip_folder, APP_ROOT.call)
      end

      def parse_time
        @option[:startTime] = @option[:startTime].xmlschema
        @option[:endTime] = @option[:endTime].xmlschema
      end

      def message
        { account: ENV['HUGO_INVEST_SERVER_YICAI_ACCOUNT'],
          password: ENV['HUGO_INVEST_SERVER_YICAI_PASSWORD']
        }.merge(@option).keep_if do |k, _|
          [ :account,
            :password,
            :nKindID,
            :startTime,
            :endTime,
            :strIndustryIDs,
            :strPlateIDs,
            :strNewslabelIDs
          ].include?(k)
        end
      end
    end
  end
end
