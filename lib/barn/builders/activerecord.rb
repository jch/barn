module Barn
  module Builders
    # Attempts to constantize a class with the same name as the factory and
    # initializes an instance from a hash returned from downstream
    #
    # # Returns ActiveRecord instance if there's a class named License
    # Barn.define :license do
    #   :expires_at => 3.days.from_now
    # end
    #
    # # Explicitly name a class
    # Barn.define :evaluation, :class => 'License' do
    #   # ...
    # end
    #
    # # Define custom traits
    # Barn.define :expired_license do
    #   build :license, \
    #     :status     => 'expired',
    #     :expires_at => 3.days.ago
    # end
    #
    # # Associations
    # Barn.define :order do
    #   :license => build(:license)
    # end
    class ActiveRecord
      def initialize(app)
        @app = app
      end

      def call(env)
        klass = begin
          (env[:factory].options[:class] || env[:factory].name.to_s.classify).constantize
        rescue NameError
          nil
        end

        object = @app.call(env)

        if klass && !object.instance_of?(klass) && klass.ancestors.include?(::ActiveRecord::Base)
          object = klass.new(object)
        end

        object
      end
    end
  end
end
