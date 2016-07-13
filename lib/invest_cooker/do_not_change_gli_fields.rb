# 填写聚源来的不应修改的字段，以确保我们没有修改
module DoNotChangeGLIFields
  extend ActiveSupport::Concern

  included do

    before_dump do
      case source
      when 'glidata'
        self.source_id = document.source_id
        [:author, :compose_organization, :created_at, :origin_date]
          .select { |attr_name| self[attr_name].blank? }
          .each   { |attr_name| self[attr_name] = document[attr_name] }

      when 'cbn'
        self.compose_organization ||= Settings.constants.compose_organization.cbn
        self.origin_url           ||= 'http://www.dtcj.com/'
        self.origin_date            = publish_at
        self.source_id              = id.to_s
      end
    end
  end
end
