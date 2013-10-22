require "barn/version"
require "barn/factory"
require "barn/namespace"
require "barn/helpers"

require "barn/builders/hash"

module Barn
  class DuplicateFactoryError < StandardError; end
  class UndefinedFactoryError < StandardError; end

  extend Namespace

  module Builders
    autoload :ActiveRecord, 'barn/builders/activerecord'
  end
end
