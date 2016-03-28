# InvestCooker::GLI::Record
# 提供更新记录聚源稿件情况
# 这个只用作更新数据，不再向 Mongo 中存数据
module InvestCooker
  module GLI
    class Record

      UPDATE_DAYS_KEY = "#{self.name}:need_update_daily"

      NEED_UPDATE_DAILY = ->(date:) {
        $redis_object.sadd UPDATE_DAYS_KEY, date.strftime('%Y%m%d')
      }

      NEED_UPDATE_DAYS = -> {
        $redis_object.smembers(UPDATE_DAYS_KEY).map { |date| TIME_ZONE.call.parse(date) }
      }

      CLEAR_UPDATE_DAYS = -> {
        $redis_object.del(UPDATE_DAYS_KEY)
      }

      class << self

        def create(data_hash)
          data_hash = data_hash.merge(invest_url: invest_url_for(data_hash[:source_id]))
          RestClient.post Settings.invest_bi.create_gli_record, data_hash.as_json
        end

        def update_daily(date: TIME_ZONE.call.now.beginning_of_day)
          client  = InvestCooker::GLI::Client.new(date)
          service = InvestCooker::GLI::Service.new(client)

          service.read_all_files do |file_name, date_str|
            ::GLI::RecordFileJob.perform_later file_name, date_str, nil, nil
          end
        end

        private

        def invest_url_for(source_id)
          lambda do |document_id|
            document_id.presence && "http://#{Settings.invest_web_url}/src/d/#{document_id}"
          end.call begin
            Document.where(source: 'glidata', source_id: source_id).first.try(:id).try(:to_s)
          end
        end
      end
    end
  end
end
