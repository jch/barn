# Getting Started

This guide is a tutorial through Barn's features. It's based on the
factory_girl [Getting Started][factory_girl_guide] guide.

## Setup

Add `barn` to your Gemfile and re-bundle. There are no extra steps for Rails.

```ruby
gem 'barn'
```

## Defining Factories

Factories are lazily evaluated blocks that are stored in Barn. The return value
of the block is what is returned by the factory when `Barn.build` is invoked.

```ruby
Barn.define :animal do
  Animal.new  # this is returned when factory is invoked
end

Barn.define :cow, :accessories => [:bell] do
  cow = build(:animal)
  cow.name  = 'Cow'
  cow.noise = 'moo'
  cow  # return built cow
end
```

You can look up factories within a Barn:

```ruby
factory = Barn.factories(:cow)
factory.class    # Barn::Factory
factory.name     # :cow
factory.options  # :accessories => [:bell]
```

Factory options are used to customize how objects are built by [build chains
](#build-chains). We'll cover this later in this guide.

## Using Factories

To create an object, call `build` with the name of the desired factory.

```ruby
cow = Barn.build(:cow)
cow.noise  # moo
```

You can also pass in additional build options to customize a particular
instance.

```ruby
cow = Barn.build(:cow, :noise => 'quack')
cow.noise  # moo
```

We expected this cow to 'quack', but those build options aren't being used by
our factory. Let's update our factory definition to support it:

```ruby
Barn.define :cow, :accessories => [:bell] do
  cow = build(:animal)
  cow.name  = build_options[:name]
  cow.noise = build_options[:noise]
  cow  # return built cow
end
```

From within your block, you can access the `build_options` passed in via build.
When we build our cow now, it confidently quacks:

```ruby
cow = Barn.build(:cow, :noise => 'quack')
cow.noise  # quack
```

## Build Chains

`build_options` allow you to customize individual factories. But that can become
tedious. That's where build chain come in. A build chain decorates objects
returned from your factories. For example:

```ruby
# build chain with one builder that merges hash attributes
Barn.build_chain = [ Barn::Builders::Hash ]

Barn.define :inventory do
  {
    :hoe  => 1,
    :rake => 5
  }
end

# options are passed to the builder, and are merged into the original instance
new_inventory = Barn.build(:inventory, :shovel => 1, :hoe => 10)
=> { :hoe => 10, :rake => 5, :shovel => 1}
```

A build chain is a list of builders that are called in order before the lazy
proc to instantiate an instance. Think of it like as Rack middleware, but for
instantiating objects. In the example above, we have a build chain with a single
builder, Barn::Builders::Hash, which merges the results of the block with
options passed into the `build` command. It's definition looks like:

```ruby
module Barn::Builders
  class Hash
    def initialize(app)
      @app = app
    end

    def call(env)
      object = @app.call(env)
      object.merge(env[:build_options])
    end
  end
end
```

Similar to Rack, `initialize` takes a downstream builder or factory to wrap
around. When an instance is needed, the `call` method is unraveled in order to
build the object. Barn::Factory objects are the last object in the build chain,
and their `call` method evaluates the defined lazy block.

## ActiveRecord or other ORMs

Hashes make great factory objects for defining functional test parameters to
post to controllers. But to test your ORM models, you can customize your build
chain to add more builders. For example, to build ActiveRecord models, add
Barn::Builders::ActiveRecord to the front of the build chain.

```ruby
Barn.build_chain = [ Barn::Builders::ActiveRecord, Barn::Builders::Hash ]

Barn.define :crop do
  {
    :unit  => 'bushel',
    :tools => [:shovel, :hoe]
  }
end

# Assuming you have a model named Crop, Barn::Builders::ActiveRecord will infer
# the class name from the name of the factory.
#
crop = Barn.build(:crop, :unit => 'sack')
crop.unit  # sack
crop.tools # [:shovel, :hoe]
```

Let's break down what happens behind the scenes when we build a Crop. When
`build` is called, we create a build chain by wrapping the builders in order:

```ruby
crop_factory = Barn.factories(:crop)  # find our factory

chain = Barn::Builders::ActiveRecord.new \
          Barn::Builders::Hash.new \
            crop_factory
```

To get our instance, we invoke `call` on our build chain and pass in the factory
and any runtime build options:

```ruby
chain.call :factory => factory, :build_options => { :unit => 'sack' }
```

Each builder `call`s the next builder in the chain. The final builder is the
factory itself and returns the result of evaluating the lazy block. This value
is passed back up the build chain and decorated.

```ruby
# returned by Factory#call
{ :unit => 'bushel', :tools => [:shovel, :hoe] }

# returned by Barn::Builders::Hash#call
{ :unit => 'sack', :tools => [:shovel, :hoe] }

# returned by Barn::Builders::ActiveRecord#call
<#Crop @unit='sack' tools=[:shovel, :hoe]>
```

## Composition

We can build composed objects by defining factories in terms of other factories.

Barn.define :silo do
  :crops => [
    build(:crop, :name => 'Potato'),
    build(:crop, :name => 'Brocoli')
  ]
end

## Prototypes and Inheritance

You may need to define a copy of a factory with a different set of attributes or
define a subclass in terms of a parent. Be careful of what objects your build
chain expects you to return. For example, Barn::Builders::Hash expects a Hash
instance, but we're directly returning an ActiveRecord object here instead. So
we need to remember to manually merge our own build options.

```ruby
Barn.define :potato do
  build :crop, {:name => 'Potato'}.merge(build_options)
end

crop = Barn.build(:potato, :unit => 'sack')
crop.unit           # sack
crop.tools          # [:shovel, :hoe]
crop.kind_of?(Crop) # true
```

## Namespaces

All factories are associated with a namespace. A namespace is a module that
extends Barn::Namespace.

```ruby
module Factory
  module Post
    extend Barn::Namespace

    define :draft {...}
    define :published {...}
  end
end

Factory::Post.build(:draft)
```

In fact, the Barn namespace is also just a module that extends Barn::Namespace.

```ruby
module Barn
  extend Barn::Namespace
end
```

## Helpers

Mix in Barn::Helpers to directly call `define` and `build` without having to
type the Barn namespace.

```ruby
# rspec
RSpec.configure do |config|
  config.include Barn::Helpers
end

# Test::Unit
class Test::Unit::TestCase
  include Barn::Helpers
end

# Cucumber
World(Barn::Helpers)

# MiniTest
class MiniTest::Unit::TestCase
  include Barn::Helpers
end

# MiniTest::Spec
class MiniTest::Spec
  include Barn::Helpers
end

# minitest-rails
class MiniTest::Rails::ActiveSupport::TestCase
  include Barn::Helpers
end
```

If a custom namespace is used, specify it with `self.barn=`

```ruby
module Factories
  extend Barn::Namespace

  define :chicken do
    # ...
  end
end

class ChickenTest < ActiveSupport::TestCase
  include Barn::Helpers
  self.barn = Factories  # specify a custom namespace

  test "eggs" do
    chicken = build(:chicken)
  end
end
```

## Lazy Attributes

All Barn factories are lazy evaluated, removing the need for a special syntax
for defining lazy attributes.

```ruby
Barn.define :user do
  :activation_code => User.generate_activation_code  # lazy eval'ed
  :date_of_birth   => 21.years.ago                   # lazy eval'ed
end
```

## Aliases

Aliases can be implemented by defining another factory. They are not recommended
because they give multiple names to the same factory, making it harder to
remember which factory is being used.

```ruby
Barn.define :user do
  # ...
end

Barn.define :post do
  { :author => build(:user) } # simple and clear, no need for an alias
end
```

## Dependent and Transient Attributes

Because everything in the block is plain ruby, you can define variables or do
any other manipulation before returning the instance.

```ruby
Barn.define :user do
  options = {
    :first_name => "Joe",
    :last_name  => "Blow"
  }.merge(build_options)

  options.merge
    :email => "#{options[:first_name].#{options[:last_name]}@example.com".downcase
end
```

## Associations

Barn does not add any special syntax or semantics for associations. Build them
as you would any other attribute.

```ruby
Barn.define :post do
  { :author => build(:user, :last_name => 'Writely') }
end
```

## Sequences

TODO: not sure how to do sequences, but also not sure they're a great idea.

Because factories are lazily evaluated, sequences are achieved with Ruby's
[Enumerable#lazy]

```ruby
Barn.define do
  (1..Float::INFINITY).lazy.yield

end
```

## Traits

TODO: not sure if this is something we should encourage

```ruby
define :story do

end

define :week_long_published_story do
  build(:published).merge \                # { :published => true }
    build(:week_long_publishing).merge \   # { :published => true, :start_at => 1.week.ago, :end_at => Time.now }
      build(:story)                        # Story instance with all the attributes above
end
```

[factory_girl_guide]: https://github.com/thoughtbot/factory_girl/blob/master/GETTING_STARTED.md
