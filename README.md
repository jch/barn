# Barn

Store lazily evaluated blocks for building test fixtures.

* Simple `define` and `build` API.
* Plain Ruby, no domain specific language.
* Extensible via [middleware interface](#build-chains).

## Usage

For a full tutorial, check out the ["Getting Started"](/docs/getting_started.md) guide.

```ruby
# Define factories with lazily evaluated blocks
Barn.define :post do
  {
    :title        => "What's Your Dream Barn Find?",
    :published_at => Time.now
  }
end

# Build instances and override default attributes
Barn.build(:post, :title => "Original Owner Jaguar E-Type For Sale")

# Compose complex objects
Barn.define :comment do
  {
    :post => build(:post),
    :body => "That's a lot of hay for a little pay."
  }
end
```

## Namespacing

When you define factories, they are stored in the global `Barn` namespace by
default. But we do allow you to create your own namespaces.

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

## Build Chains

A build chain is a list of builders that are called to instantiate an instance.
It's the same concept as Rack middleware, but we build object instances instead
of HTTP responses. A builder is anything that responds to `build` and returns a
contructed object. An environment hash of available options to passed to
`build`. The default build chain has one builder,
[Barn::Builders::Hash](/lib/barn/builders/hash.rb), that merges attributes into
a hash. See [/lib/barn/builders](/lib/barn/builders) for more examples.

```ruby
# Inspect a build chain
Barn.build_chain
=> [Barn::Builders::Hash]  # Default is to merge hash attributes

# After building hash attributes, instantiates an ActiveRecord object
Barn.build_chain.unshift Barn::Builders::ActiveRecord

# Instrument the time it takes to run a build chain
Barn.build_chain.unshift Barn::Builders::Instrumentation

Barn.build_chain
=> [Barn::Builders::Instrumentation, Barn::Builders::ActiveRecord, Barn::Builders::Hash]
```

## Helpers

Barn provides helpers to let you type less in your tests. Include
`Barn::Helpers` to skip typing `Barn.build` and `Barn.define`.

```ruby
# RSpec
RSpec.configure { |c| c.include Barn::Helpers }

describe "Post" do
  it "requires a title" do
    post = build(:post)
  end
end

# ActiveSupport::TestCase with a custom namespaced Barn
class PostTest < ActiveSupport::TestCase
  include Barn::Helpers
  self.barn = Factory::Post

  test "requires a title" do
    post = build(:post)
  end
end
```

## Installation

Add this line to your application's Gemfile:

    gem 'barn'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install barn

## Contributing

Check out [this guide](/CONTRIBUTING.md) if you'd like to
contribute.

## License

This project is licensed under the [MIT License](/LICENSE.txt)

