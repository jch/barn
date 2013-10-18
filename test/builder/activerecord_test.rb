require "test_helper"
require "active_record"

class ::User < ActiveRecord::Base
end

module Builder
  class ActiveRecordTest < MiniTest::Test

    def setup
      ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"
      capture_io do
        ActiveRecord::Schema.define do
          create_table :users do |t|
            t.string :email
          end
        end
      end
      Barn.reset
      Barn.build_chain = [ Barn::Builders::ActiveRecord ]
    end

    def test_activerecord
      Barn.define :user do
        {:email => "jollyjerry@gmail.com"}
      end
      assert_kind_of User, Barn.build(:user)
    end

    def test_explicit_class_reference
      Barn.define :foo, :class => 'User' do
        {:email => "foo@gmail.com"}
      end
      assert_kind_of User, Barn.build(:foo)
    end

    def test_custom_traits
      Barn.define :user do
      end
      Barn.define :custom do
        build :user, :email => 'wut'
      end
      foo = Barn.build(:custom)
      assert_kind_of user, foo
      assert_equal 'wut', foo.email
    end
  end
end
