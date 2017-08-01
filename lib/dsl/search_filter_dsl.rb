concern :SearchFilterDSL do

  def filters(&block)
    if block.present?
      @filters = {}
      class_exec(&block)
    else
      @filters
    end
  end

  def before(&block)
    @before = block if block.present?
    @before
  end

  private

  def filter(key: nil, name:, title:, type: :multi, &block)
    key ||= name
    @filters[key] = {name: name, title: title, type: type}
    @this_filter = key
    class_exec(&block)
  end

  # 数据的集合
  def collection(&block)
    @filters[@this_filter][:collection] = block
  end

  [
    :title,        # 展示的值
    :value,        # 回传的值
    :sort,         # 排序
    :type,         # 筛选项的类型
    :parent_value, # 指向父节点的值
    :description   # 附带描述信息
  ].each do |key|
    define_method(key) do |&block|
      @filters[@this_filter][:"#{key}_block"] = block
    end
  end
end
