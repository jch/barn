require "barn"
require "minitest/autorun"
require "active_record"

class User < ActiveRecord::Base
end

class Crop < ActiveRecord::Base
end

class Organization < ActiveRecord::Base
  has_one :license
end

class License < ActiveRecord::Base
  belongs_to :organization
end

module Builder
  class ActiveRecordTest < MiniTest::Test

    def setup
      ActiveRecord::Base.establish_connection :adapter => "sqlite3",
                                              :database => ":memory:"
      capture_io do
        ActiveRecord::Schema.define do
          create_table :users do |t|
            t.string :email
          end
            create_table :crops do |t|
            t.string :name
            t.string :unit
          end
          create_table :organizations do |t|
            t.string :name
          end
          create_table :licenses do |t|
            t.datetime :expires_at
            t.integer :organization_id
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
      Barn.define :foo, :class => "User" do
        {:email => "foo@gmail.com"}
      end
      assert_kind_of User, Barn.build(:foo)
    end

    def test_association
      Barn.define :organization do
        {:name => "Foo"}
      end

      Barn.define :license do
        {
          :organization => build(:organization),
          :expires_at => Time.gm(2013,03,30)
        }
      end

      license = Barn.build :license
      assert_equal Time.gm(2013,03,30), license.expires_at
      assert_equal "Foo", license.organization.name
      assert_kind_of Organization, license.organization
    end

    def test_association_build_options
      Barn.define :organization do
        {:name => "Foo"}
      end

      Barn.define :license do
        {
          :organization => build(:organization),
          :expires_at => Time.gm(2013,03,30)
        }
      end

      license = Barn.build :license, :expires_at => Time.gm(2014,11,01)
      assert_equal Time.gm(2014,11,01), license.expires_at
    end

    def test_custom_trait
      Barn.define :organization do
        {:name => "Foo"}
      end

      Barn.define :something do
        build :organization, :name => "something"
      end

      something = Barn.build :something
      assert_equal "something", something.name
      assert_kind_of Organization, something
    end

    def test_prototypes_and_inheritance
      Barn.define :crop do
        {
          :name => "Apple",
          :unit => "bushel"
        }
      end

      Barn.define :potato, :class => "Crop" do
        build(:crop, :name => "Potato")
      end

      crop = Barn.build(:potato, :unit => "sack")
      assert_equal "sack", crop.unit
      assert_equal "Potato", crop.name
      assert_kind_of Crop, crop
    end
  end
end
