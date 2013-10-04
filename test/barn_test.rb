require "barn"
require "minitest/autorun"
require "active_record"

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
    assert_equal "jollyjerry@gmail.com", user[:email]
  end

  def test_build_override
    user = Barn.build(:user, :email => "jch@whatcodecraves.com")
    assert_equal "jch@whatcodecraves.com", user[:email]
  end

  def test_build_unknown

  end

  def test_build_chain_hash_last
    active_record = Barn::Builders::ActiveRecord
    hash = Barn::Builders::Hash

    assert_equal hash, Barn.build_chain.last

    Barn.build_chain = [ active_record, hash ]
    assert_equal hash, Barn.build_chain.last

    Barn.build_chain = [ hash, active_record ]
    assert_equal hash, Barn.build_chain.last

    Barn.build_chain = [ active_record ]
    assert_equal hash, Barn.build_chain.last
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

end
