require 'barn'
require 'minitest/autorun'
require 'active_record'
require 'debugger'

class BarnTest < MiniTest::Test
  def setup
    Barn.reset
    Barn.define :user do
      {:email => "jollyjerry@gmail.com"}
    end
  end

  def test_define
    assert Barn.factories[:user]
  end

  def test_double_define_error
  end

  def test_build
    user = Barn.build(:user)
    assert_equal 'jollyjerry@gmail.com', user[:email]
  end

  def test_build_override
    user = Barn.build(:user, :email => 'jch@whatcodecraves.com')
    assert_equal 'jch@whatcodecraves.com', user[:email]
  end

  def test_build_unknown

  end

  def test_helpers
    custom_barn = Module.new do
      extend Barn::Namespace

      define :foo
    end

    klass = Class.new do
      include Barn::Helpers
      self.barn = custom_barn

      define :bar
    end

    assert custom_barn.factories[:foo]
    assert custom_barn.factories[:bar]
  end

  class ::User < ActiveRecord::Base
  end

  def test_activerecord
    ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
    capture_io do
      ActiveRecord::Schema.define do
        create_table :users do |t|
          t.string :email
        end
      end
    end
    Barn.build_chain.unshift Barn::Builders::ActiveRecord

    assert_kind_of User, Barn.build(:user)
  end
end
