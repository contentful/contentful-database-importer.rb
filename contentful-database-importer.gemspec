# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'contentful/database_importer/version'

Gem::Specification.new do |spec|
  spec.name          = "contentful-database-importer"
  spec.version       = Contentful::DatabaseImporter::VERSION
  spec.authors       = ["Contentful GmbH (David Litvak Bruno)"]
  spec.email         = ["david.litvak@contentful.com"]

  spec.summary       = %q{Tool to import content from a Database to Contentful}
  spec.description   = %q{Tool to import content from a Database to Contentful}
  spec.homepage      = "https://contentful.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'contentful_bootstrap', '~> 3.0'
  spec.add_dependency 'contentful-management', '~> 0.9'
  spec.add_dependency 'sequel', '~> 4.39'
  spec.add_dependency 'base62-rb'
  spec.add_dependency 'mimemagic'

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'pry'
end
