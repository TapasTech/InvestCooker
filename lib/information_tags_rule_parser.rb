class InformationTagsRuleParser
  attr_accessor :rule

  def initialize(rule)
    self.rule = case rule
                when String
                  rule
                else
                  rule.to_a
                    .reject { |r| r.try(:name).blank? || r.try(:value).blank? }
                    .map { |r| [r.name, clear_format(r.value)] }
                    .reject { |n, v| v.blank? }
                    .map { |n, v| "#{n}:#{v}" }
                    .join("\n")
                end
  end

  # 清除换行空格等
  private def clear_format(rule_value)
    rule_value
      .gsub(' ', '')
      .gsub("\n", '')
      .gsub("`", '') # 支持显示高亮
      .strip
  end

  F = {
    '栏目='    => ->(i, c) { i.column_names.include?(c) },
    '标题开头为' => ->(i, c) { i.title&.index(c) == 0 },
    '专题为'    => ->(i, c) { i.special_subjects.include?(c) },
    '内容标签为' => ->(i, c) { i.tag_info&.content_tags.to_a.include?(c) },
    '子栏目为' => ->(i, c) { i.tag_info&.sub_column == c },
    '子栏目不为' => ->(i, c) { i.tag_info&.sub_column != c },
    '运营标签为' => ->(i, c) { i.tag_info&.opr_tags.to_a.map(&:name).include?(c) },
    '配图为' => ->(i, c) { i.thumbnail_type == c },
    '来源为' => ->(i, c) { i.origin_website == c },
    '来源不为' => ->(i, c) { i.origin_website != c },
    '头图为' => ->(i, c) { i.cover_pictures.present? }, # NOTE 目前只校验存在
    '作者不为' => ->(i, c) { i.author != c },
    '作者为' => ->(i, c) { i.author == c },
    '稿件类型为' => -> (i, c) { i.display_type == c },
    '视频审核状态为' => -> (i, c) { i.video_audit_state == c },
    '发布到了' => -> (i, c) { i.display_published_receiver_names.to_a.include?(c) }
  }

  VS = -> (f, e) {
    f.split(e).last.split(',').map(&:strip).map do |c|
      ->(i) { F[e].call(i, c) }
    end
  }

  FS = ->(f) {
    vs = F.keys.select { |k| f.index(k) }
    fail "invalid rule: #{f}" unless vs.present? && vs.size == 1
    fail "invalid rule: #{f}" if f.scan(vs.first).size > 1
    VS.(f, vs.first)
  }

  TS = ->(t) { ->(d) { d.split(t).map(&:strip) } }

  AND = ->(fs) { -> (i) { fs.reject { |f| f.(i) }.blank? } }
  OR = ->(fs) { -> (i) { fs.select { |f| f.(i) }.present? } }

  def config
    rule.split("\n").reject(&:blank?).map do |line|
      n, d = line.split(':')
      n.strip! rescue fail "rule name should be present rule[name:value]: #{line}"
      d.strip! rescue fail "rule value should be present rule[name:value]: #{line}"

      v = parse(d,
        [TS.('且!'), AND],
        [TS.('或'), OR],
        [TS.('且'), AND]
      )

      [n, OpenStruct.new(validation: v)]
    end.to_h
  end

  # 递归生成校验函数
  def parse(d, *ts_as)
    ts, a = ts_as.shift
    return OR.(FS.(d)) if ts.blank?
    a.(ts.(d).map { |dx| parse(dx, *ts_as) })
  end
end
