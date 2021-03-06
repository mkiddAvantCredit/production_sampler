# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'production_sampler/version'

Gem::Specification.new do |spec|
  spec.name          = "production_sampler"
  spec.version       = ProductionSampler::VERSION
  spec.authors       = ["Winston Kotzan"]
  spec.email         = ["winston.kotzan@avant.com"]

  spec.summary       = %q{A means to extract fixtures from your production database.}
  #spec.description   = %q{TODO: Write a longer description or delete this line.}
  #spec.homepage      = "TODO: Put your gem's website or public repo URL here."

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.test_files    = Dir["spec/**/*"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  # spec.add_development_dependency "pry",  "~> 0.10"
  # spec.add_development_dependency "pry-byebug",  "~> 3.2"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec-rails", "~> 3.2"
  spec.add_development_dependency "sqlite3"

  spec.add_runtime_dependency "activerecord", ">= 3.2"
  spec.add_runtime_dependency "activesupport", ">= 3.2"
  spec.add_runtime_dependency "hashie"
  spec.add_runtime_dependency "monetize", ">= 1.0"
  spec.add_runtime_dependency "money-rails", ">= 1.4.1"
end
