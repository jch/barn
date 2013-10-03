require "barn"
require "minitest/autorun"

class Animal; attr_accessor :name, :noise; end

module Builder
  class HashTest < MiniTest::Test
    def setup
      Barn.reset
      Barn.define :animal do
        Animal.new
      end
    end

    def test_factory_look_up
      factory = Barn.factories[:animal]
      assert_equal Barn::Factory, factory.class
      assert_equal :animal, factory.name
      assert_equal Hash.new, factory.options
    end

    def test_define_context
      Barn.define :cow, :accessories => [:bell] do
        cow = build(:animal)
        cow.name  = "Cow"
        cow.noise = "moo"
        cow
      end

      cow = Barn.build(:cow)
      assert_equal "Cow", cow.name
      assert_equal "moo", cow.noise
      assert_kind_of Animal, cow
    end

    def test_additional_build_options
      Barn.define :cow, :accessories => [:bell] do
        cow = build(:animal)
        cow.name  = "Cow"
        cow.noise = "moo"
        cow
      end

      cow = Barn.build(:cow, :noise => "quack")
      assert_equal "Cow", cow.name
      assert_equal "quack", cow.noise
      assert_kind_of Animal, cow
    end
  end
end
