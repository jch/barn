require 'forwardable'

module Barn
  # Forwards all `define` and `build` calls to a barn configured on the class.
  #
  # class SomeTest
  #   include Barn::Helpers
  #   self.barn = MyCustomBarn
  # end
  module Helpers
    def self.included(base)
      base.class_eval do
        extend Forwardable
        def_delegators :"self.class.barn", :define, :build

        class <<self
          extend Forwardable
          def_delegators :"self.barn", :define, :build

          attr_writer :barn
          def barn
            @barn || ::Barn
          end
        end
      end
    end
  end

end
