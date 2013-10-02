source "https://rubygems.org"

# Specify your gem's dependencies in barn.gemspec
gemspec

group :debug do
  if RUBY_VERSION > "1.9"
    gem "debugger"
  else
    gem "ruby-debug"
  end
end
