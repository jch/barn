require "barn"
require "minitest/autorun"

# http://about.travis-ci.org/docs/user/languages/ruby/#Exclude-non-essential-gems-like-ruby-debug-from-your-Gemfile
unless ENV["CI"]
  if RUBY_VERSION > "1.9"
    require "debugger"
  else
    require "ruby-debug"
  end
end
