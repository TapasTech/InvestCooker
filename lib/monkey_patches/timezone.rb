class ActiveSupport::TimeZone
  parse_with_process_chinese = Module.new do
    def parse(str, now = self.now)
      if str =~ /前|ago/
        d = str.to_i
        if str =~ /秒|second/
          d = d.seconds
        elsif str =~ /分|minute/
          d = d.minutes
        elsif str =~ /时|hour/
          d = d.hours
        elsif str =~ /[天日]|day/
          d = d.days
        elsif str =~ /月|month/
          d = d.months
        elsif str =~ /年|year/
          d = d.years
        end
        return now - d
      end

      if str =~ /[年月日时分秒-]/
        str.gsub!(/[\s\u00a0]*(\d+)[\s\u00a0]*[年月-]/, '\1/')
        str.gsub!(/[\s\u00a0]*(\d+)[\s\u00a0]*[时点分]/, '\1:')
        str.gsub!(/[\s\u00a0]*(\d+)[\s\u00a0]*[日秒]([\s\u00a0]*)/, '\1 \2')
      end

      super(str, now)
    end
  end

  prepend parse_with_process_chinese
end
