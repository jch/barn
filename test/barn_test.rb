require "test_helper"

class BarnTest < MiniTest::Test
  def setup
    Barn.reset
    Barn.build_chain = [ Barn::Builders::Hash ]
    Barn.define :user do
      {:email => "jollyjerry@gmail.com"}
    end
  end

  def test_define
    assert Barn.factories[:user]
  end

  def test_double_define_error
    error = assert_raises Barn::DuplicateFactoryError do
      Barn.define :user
    end
    assert_equal "factory `user' already defined", error.message
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
    error = assert_raises Barn::UndefinedFactoryError do
      Barn.build :unknown
    end
    assert_equal "factory `unknown' not defined", error.message
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
