# 用来记录当前使用的 CDN
module InvestAdmin
  class BusHandler
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name,  type: String
    field :value, type: String

    def self.sync!
      %w(filter driver modifier adapter).each do |name|
        Dir.foreach("#{Rails.root}/app/#{name}s")
           .select { |n| n =~ /\.rb/ }
           .map{ |n| n.split('.').first.camelize }
           .each { |v| InvestAdmin::BusHandler.find_or_create_by(name: name, value: v) }
      end
    end
  end
end
