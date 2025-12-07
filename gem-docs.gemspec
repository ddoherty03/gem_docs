# frozen_string_literal: true


spec.files = Dir["lib/**/*.rb"]

spec.add_dependency "rake"


require_relative "lib/gem/docs/version"

Gem::Specification.new do |spec|
  spec.name = "gem-docs"
  spec.version = Gem::Docs::VERSION
  spec.authors = ["Daniel E. Doherty"]
  spec.email = ["ded@ddoherty.net"]

  spec.summary       = "Unified documentation automation for Ruby gems"
  spec.description   = "Shared tasks for README.org execution, GFM export, YARD integration (future), etc."
  spec.homepage = "https://github.com/ddoherty03/gem-docs"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ddoherty03/gem-docs"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rake"
end
