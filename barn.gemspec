# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'barn/version'

Gem::Specification.new do |spec|
  spec.name          = "barn"
  spec.version       = Barn::VERSION
  spec.authors       = ["Jerry Cheung"]
  spec.email         = ["jch@whatcodecraves.com"]
  spec.description   = %q{Store lazily evaluated blocks for building test fixtures}
  spec.summary       = %q{Small no-magic library for building test factories}
  spec.homepage      = "https://github.com/jch/barn"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "sqlite3"
end
