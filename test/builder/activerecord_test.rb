require 'barn'
require 'minitest/autorun'
require 'active_record'
require 'debugger'

class ::User < ActiveRecord::Base
end

module Builder
  class ActiveRecordTest < MiniTest::Test

    def setup
      ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
      capture_io do
        ActiveRecord::Schema.define do
          create_table :users do |t|
            t.string :email
          end
        end
      end
      Barn.reset
      Barn.build_chain.clear
      Barn.build_chain.unshift Barn::Builders::Hash
      Barn.build_chain.unshift Barn::Builders::ActiveRecord
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
  end
end
