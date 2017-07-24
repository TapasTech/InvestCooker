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

  # 展示的值
  def title(&block)
    @filters[@this_filter][:title_block] = block
  end

  # 回调的值
  def value(&block)
    @filters[@this_filter][:value_block] = block
  end

  # 排序
  def sort(&block)
    @filters[@this_filter][:sort_block] = block
  end

  # 筛选项的类型
  def type(&block)
    @filters[@this_filter][:type_block] = block
  end

  # 附带描述信息
  def description(&block)
    @filters[@this_filter][:description_block] = block
  end
end
