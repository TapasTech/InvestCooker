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

  def filter(name:, title:, &block)
    @filters[name] = {title: title}
    @this_filter = name
    class_exec(&block)
  end

  def collection(&block)
    @filters[@this_filter][:collection] = block
  end

  def title(&block)
    @filters[@this_filter][:title_block] = block
  end

  def value(&block)
    @filters[@this_filter][:value_block] = block
  end

  def sort(&block)
    @filters[@this_filter][:sort_block] = block
  end

  def description(&block)
    @filters[@this_filter][:description_block] = block
  end
end
