module Barn
  # maybe Proc already defines __FILENAME__ and __LINENUMBER__
  class Factory
    # help with debugging where something was defined
    attr_accessor :filename, :line

    attr_reader :name, :options

    def initialize(name, options = {}, &blk)
      @name    = name
      @options = options
      @blk     = blk
    end

    # Returns built object
    def call(env)
      Barn.instance_eval(&@blk)
    end
  end
end
