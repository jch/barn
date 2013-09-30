module Barn
  module Namespace
    attr_writer :build_chain

    def define(name, factory_options = {}, &blk)
      blk ||= Proc.new {}
      factories[name] = Factory.new(name, factory_options, &blk)
    end

    def build(name, build_options = {})
      factory = factories[name]

      chained_builder = build_chain.reverse.reduce(factory) do |final, builder|
        builder.new(final)
      end  # not caching this for simplicity

      chained_builder.call \
        :factory => factory,
        :args    => build_options
    end

    def build_chain
      @build_chain ||= [Barn::Builders::Hash]
    end

    def factories
      @factories ||= {}
    end

    def reset
      @computed_chain = nil
      @factories = {}
    end
  end
end
