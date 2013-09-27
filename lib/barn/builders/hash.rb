module Barn
  module Builders
    class Hash
      def initialize(app)
        @app = app
      end

      # `env` is a hash with:
      #    :name    - symbol name of the factory
      #    :options - optional params passed to `Barn.define`
      #    :args    - parameters passed to the block of`Barn.build`
      def call(env)
        object = @app.call(env)
        object.merge(env[:args])
      end
    end
  end
end
