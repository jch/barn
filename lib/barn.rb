require "barn/version"
require "barn/factory"
require "barn/namespace"
require "barn/helpers"

require "barn/builders/hash"

module Barn
  # Public: Error raised when a Barn::Factory has already been defined.
  #
  # Examples
  #
  #   > Barn.define(:user)
  #   => #<Barn::Factory:0x007fb4fd2ca998...>
  #   > Barn.define(:user)
  #   Barn::DuplicateFactoryError: factory `user' already defined
  class DuplicateFactoryError < StandardError; end

  # Public: Error raised when building an undefined Barn::Factory.
  #
  # Examples
  #
  #   > Barn.build(:user)
  #   Barn::UndefinedFactoryError: factory `user' not defined
  class UndefinedFactoryError < StandardError; end

  extend Namespace

  module Builders
    autoload :ActiveRecord, 'barn/builders/activerecord'
  end
end
