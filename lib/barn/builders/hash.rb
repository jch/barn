module Barn
  module Builders
    class Hash
      def initialize(app)
        @app = app
      end

      def call(env)
        object = @app.call(env)
        object.merge(env[:args])
      end
    end
  end
end
