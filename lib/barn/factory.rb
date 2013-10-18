module Barn
  # maybe Proc already defines __FILENAME__ and __LINENUMBER__
  class Factory
    # help with debugging where something was defined
    attr_accessor :filename, :line

    attr_reader :name, :options

    # Generate a Barn instance.
    #
    #   name    - The String of the Barn Factory definition
    #   klass   - The class or namespace of the Barn to run the block.
    #   options - A Hash of options
    #   blk     - Barn factory defintion blockk.
    #
    def initialize(name, klass, options = {}, &blk)
      @name    = name
      @klass   = klass
      @options = options
      @blk     = blk
    end

    # Returns built object
    def call(env)
      @klass.instance_exec env, &@blk
    end
  end
end
