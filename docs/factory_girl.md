# Comparison with Factory Girl

This guide is a work in progress comparing Barn's interface with [Factory Girl][factory_girl].

### Defining Factories

Factories are lazily evaluated blocks that are stored in Barn. The return value
of the block is what is returned by the factory when `Barn.build` is invoked.

```ruby
Barn.define :animal do
  Animal.new  # this is returned when factory is invoked
end

Barn.define :cow do
  cow = build(:animal)
  cow.name  = 'Cow'
  cow.noise = 'moo'
  cow  # return built cow
end
```

### Using Factories

Barn supports only a single interface, `build`, for creating objects:

```ruby
cow = Barn.build(:cow)
cow.noise  # moo
```

### Build Chains

Build chains allow you to decorate objects returned from your factories. For
example:

```ruby
# build chain with one builder
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

A build chain is a list of builders that are called to instantiate an instance.
Think of it like as Rack middleware, but for instantiating factories. In the
example above, we have a build chain with a single builder,
Barn::Builders::Hash, which merges the results of the block with options passed
into the `build` command.

To build ActiveRecord models, add another builder to the build chain:

```ruby
Barn.build_chain = [ Barn::Builders::ActiveRecord, Barn::Builders::Hash ]

# Assuming you have a model named Crop, Barn::Builders::ActiveRecord will infer
# the class name from the name of the factory.
Barn.define :crop do
  {
    :unit  => 'bushel',
    :tools => [:shovel, :hoe]
  }
end
```

Let's break down what happens behind the scenes when we build a Crop
`Barn.build`. First, we find a factory for `:crop`:

```ruby
factory = Barn.factories(:crop)
factory.options  # {}

factory = Barn.factories(:potato)
factory.options  # { :class => 'Crop' }
```

A [Barn::Factory][factory] wraps around the definition block and any options
declared with it. In this case, we didn't pass in any additional parameters
because the model name is the same as the factory name.

When `build` is called, the first thing we do is to create a build chain by
wrapping the builders in order:

```ruby
chain = Barn::Builders::ActiveRecord.new \
          Barn::Builders::Hash.new \
            factory  # the factory instance
```

To get our instance, we invoke `call` on our build chain and pass in the factory
and any runtime build options:

```ruby
# crop
chain.call :factory => factory, :args => { :unit => 'sack' }
```

Each builder `call`s the next builder in the chain. The final builder is the
factory itself and the first to return an object:

Because of the order of our build chain, we see that the factory is the first to
return an object:

```ruby
factory.call :factory => factory, :args => { :unit => 'sack' }
=> <#Crop @unit='sack' @tools=[:shovel, :hoe]>
```


We can compose more complex objects by defining factories in terms of other
factories:

```ruby
# Explicitly specify a class to instantiate
Barn.define :potato, :class => 'Crop' do
  build(:crop, :name => 'Potato')
end

crop = Barn.build(:potato, :unit => 'sack')
crop.unit           # sack
crop.tools          # [:shovel, :hoe]
crop.kind_of?(Crop) # true
```

Since we can't infer the class Crop from the factory name :potato, we pass in an
explicit class name so the ActiveRecord builder knows what class to instantiate.

See [/lib/barn/builders](/lib/barn/builders) for more examples.

```ruby
# Returns a User instance that's not saved
user = FactoryGirl.build(:user)

# Returns a saved User instance
user = FactoryGirl.create(:user)

# Returns a hash of attributes that can be used to build a User instance
attrs = FactoryGirl.attributes_for(:user)

# Returns an object with all defined attributes stubbed out
stub = FactoryGirl.build_stubbed(:user)

# Passing a block to any of the methods above will yield the return object
FactoryGirl.create(:user) do |user|
  user.posts.create(attributes_for(:post))
end
```

Barn supports only `build`:

```ruby
# Returns a User instance that's not saved.
user = Barn.build(:user)

# If a persisted instance is needed, call save.
user = Barn.build(:user).save
```

`attributes_for` is often useful for functional or integration tests, but it
overloads model factories with an extra responsibility. Instead, consider
creating another factory for desired attributes. For example, instead of
grabbing the attributes out of a User, define a `user_signup` factory:

```ruby
Barn.define :user_signup do
  # ... attributes for creating a user
end
```

`build_stubbed and the yield block for aren't supported because it's easy enough
to do those in normal Ruby.

### Helpers

FactoryGirl provides a mixin `FactoryGirl::Syntax::Methods` to skip typing out
`FactoryGirl`. Barn does the same with `Barn::Helpers`

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


### Lazy Attributes

All Barn factories are lazy evaluated, removing the need for a special syntax
for defining lazy attributes.

```ruby
FactoryGirl.factory :user do
  activation_code { User.generate_activation_code }
  date_of_birth   { 21.years.ago }
end

Barn.define :user do
  :activation_code => User.generate_activation_code
  :date_of_birth   => 21.years.ago
end
```

### Aliases

Aliases can be implemented by defining another factory. They are not recommended
because they give multiple names to the same factory, making it harder to
remember which factory is being used.

```ruby
FactoryGirl.define do
  factory :user, aliases: [:author] do
    # ...
  end

  factory :post do
    author
    # instead of
    # association :author, factory: :user
  end
end

Barn.define :user do
  # ...
end

Barn.define :post do
  { :author => build(:user) } # simple and clear, no need for an alias
end
```

### Dependent Attributes

```ruby
FactoryGirl.factory :user do
  first_name "Joe"
  last_name  "Blow"
  email { "#{first_name}.#{last_name}@example.com".downcase }
end

Barn.define :user do
  {
    :first_name => "Joe",
    :last_name  => "Blow",
    :email => "#{first_name}.#{last_name}@example.com".downcase
  }
end
```

## Transient Attributes

> There may be times where your code can be DRYed up by passing in transient attributes to factories.

```ruby
FactoryGirl.factory :user do
  ignore do
    rockstar true
    upcased  false
  end

  name  { "John Doe#{" - Rockstar" if rockstar}" }
  email { "#{name.downcase}@example.com" }

  after(:create) do |user, evaluator|
    user.name.upcase! if evaluator.upcased
  end
end

FactoryGirl.create(:user, upcased: true).name
#=> "JOHN DOE - ROCKSTAR"
```

Since Barn factory definitions is not a DSL, any valid Ruby code can be
specified in the block. The last line of the block is returned as the object
built.

```ruby
Barn.define :user do
  name = "John Doe"
  name << "- Rockstar" if args[:rockstar]
  name.upcase! if args[:upcased]

  { :name => name }
end

Barn.build(:user, :upcased => true).name
```

## Associations

Barn does not add any special syntax or semantics for associations.

```ruby
FactoryGirl.define do
  factory :post do
    # ...
    author
  end

  # You can also specify a different factory or override attributes:
  factory :post do
    # ...
    association :author, factory: :user, last_name: "Writely"
  end
end

####### Barn #######

Barn.define :post do
  { :author => build(:user, :last_name => 'Writely') }
end
```

## Inheritance

```ruby
factory :post do
  title "A title"

  factory :approved_post do
    approved true
  end
end

approved_post = FactoryGirl.create(:approved_post)
approved_post.title    # => "A title"
approved_post.approved # => true
```

To reuse attributes from other factories in Barn,

```ruby
define :post do
  { :title => "A title" }
end

define :approved_post do
  build(:title, :approved => true)
end
```

Barn also allows you to organize your factories with namespaces:

```ruby
module Factories
  module Post
    extend Barn::Namespace

    define :basic do
      { :title => "A title" }
    end

    define :approved do
      build :basic, :approved => true
    end
  end
end
```

### Sequences

TODO: what's the point of sequences?

Because factories are lazily evaluated, sequences are achieved with Ruby's
[Enumerable#lazy]

```ruby
# Defines a new sequence
FactoryGirl.define do
  sequence :email do |n|
    "person#{n}@example.com"
  end
end

FactoryGirl.generate :email
# => "person1@example.com"

FactoryGirl.generate :email
# => "person2@example.com"

Barn.define do
  (1..Float::INFINITY).lazy.yield

end
```

Interesting problem, how do you pass in nested attributes?

Barn.build(:post, :author => build(:user, :last_name => "Baz")) # works, but verbose


### Traits

> Traits allow you to group attributes together and then apply them to any factory.

```ruby
define :story do

end

define :week_long_published_story do
  build(:published).merge \                # { :published => true }
    build(:week_long_publishing).merge \   # { :published => true, :start_at => 1.week.ago, :end_at => Time.now }
      build(:story)                        # Story instance with all the attributes above
end
```

One gotcha to be aware of is the order of how factories are built matters...
TODO: explain more


### Callbacks

These aren't needed because there are not different build strategies in Barn.

### Custom Construction

```ruby
Barn.define :custom_object do
  CustomObject.create('special', :param1 => 'arguments')
end
```

* TODO: This would fail custom construction... Maybe Builders::Hash should check

* Simple interface: `define` templates for your objects, and `build` to
  instantiate them.
*
