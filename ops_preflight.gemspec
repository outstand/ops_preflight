# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ops_preflight/version'

Gem::Specification.new do |gem|
  gem.name          = "ops_preflight"
  gem.version       = OpsPreflight::VERSION
  gem.authors       = ["Ryan Schlesinger"]
  gem.email         = ["ryan@instanceinc.com"]
  gem.description   = %q{Preflight and deploy applications}
  gem.summary       = %q{Preflight by packaging the bundle, precompiled assets, or anything else needed to deploy an application.}
  gem.homepage      = "https://github.com/aceofsales/ops_preflight"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency('thor', '~> 0.17.0')
  gem.add_runtime_dependency('fog', '~> 1.10')
  gem.add_runtime_dependency('mina', '~> 0.3.0')
  gem.add_runtime_dependency('aws-sdk', '~> 1.33')
  gem.add_runtime_dependency('multi_json', '~> 1.0')
end
