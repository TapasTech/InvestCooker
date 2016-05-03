class BaseDocumentParser
  class << self

    def dump(document, options={})
      # 特殊情况不用全部 dump
      hash = @skip_dump && document.instance_exec(options, @skip_dump) || evaluate_result(document, options)

      # dump 前处理 document
      @before_dumps.each { |block| evaluate_considering_block_arity(document, options, block) }

      # dump 后处理结果
      @after_dumps.reduce(hash) { |result, block| evaluate_considering_block_arity(document, result, block) }
    end

    def skip_dump(&block)
      @skip_dump ||= block
    end

    def after_dump(&block)
      @after_dumps ||= []
      @after_dumps << block
    end

    def before_dump(&block)
      @before_dumps ||= []
      @before_dumps << block
    end

    def attribute(name, &block)
      @attributes ||= {}
      @attributes[name] = block
    end

    private

    def evaluate_result(document, options)
      @attributes.each_pair.mash do |name, block|
        [name, evaluate_considering_block_arity(document, options, block)]
      end
    end

    def evaluate_considering_block_arity(document, options, block)
      if block.arity.zero?
        document.instance_exec(&block)
      else
        document.instance_exec(options, &block)
      end
    end
  end
end
