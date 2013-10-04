module Barn
  module Builders
    class Hash
      def initialize(app)
        @app = app
      end

      def call(env)
        object = @app.call(env)

        if env[:args].is_a?(::Hash)
          if object.respond_to?(:merge)
            object.merge!(env[:args])
          else
            env[:args].each do |key, value|
              object.send("#{key}=", value)
            end
          end
        end

        object
      end
    end
  end
end
