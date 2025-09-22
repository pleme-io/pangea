# frozen_string_literal: true

lib = File.expand_path(%(lib), __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative %(lib/pangea/version)

Gem::Specification.new do |spec|
  spec.name                  = %(pangea)
  spec.version               = Pangea::VERSION
  spec.authors               = [%(Luis Zayas)]
  spec.email                 = [%(drzthslnt@gmail.com)]
  spec.description           = %(Scalable infrastructure management with Ruby DSL compilation to Terraform JSON. Features template-level state isolation and automation-first design.)
  spec.summary               = %(Infrastructure management with Ruby DSL and Terraform)
  spec.homepage              = %(https://github.com/drzln/#{spec.name})
  spec.license               = %(Apache-2.0)
  spec.require_paths         = [%(lib)]
  spec.executables << %(pangea)
  spec.required_ruby_version = %(>=3.3.0)

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "debug", "~> 1.8"
  spec.add_development_dependency "rubocop", "~> 1.57"
  spec.add_development_dependency "ruby-lsp", "~> 0.13"
  spec.add_development_dependency "rubocop-rake", "~> 0.6"
  spec.add_development_dependency "rubocop-rspec", "~> 3.0"
  spec.add_development_dependency "debug_inspector", "~> 1.1"
  spec.add_development_dependency "rbs", "~> 3.2"
  spec.add_development_dependency "steep", "~> 1.6"
  spec.add_development_dependency "typeprof", "~> 0.21"
  spec.add_development_dependency "bundler-audit", "~> 0.9"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "simplecov-lcov", "~> 0.8"

  spec.add_dependency "tty-config", "~> 0.5"
  spec.add_dependency "tty-option", "~> 0.3"
  spec.add_dependency "tty-table", "~> 0.12"
  spec.add_dependency "tty-spinner", "~> 0.9"
  spec.add_dependency "tty-progressbar", "~> 0.18"
  spec.add_dependency "tty-logger", "~> 0.6"
  spec.add_dependency "tty-box", "~> 0.7"
  spec.add_dependency "pastel", "~> 0.8"
  spec.add_dependency "diff-lcs", "~> 1.5"
  spec.add_dependency "rexml", "~> 3.2"
  spec.add_dependency "bundler", "~> 2.4"
  spec.add_dependency "toml-rb", "~> 2.2"
  spec.add_dependency "aws-sdk-s3", "~> 1.140"
  spec.add_dependency "aws-sdk-dynamodb", "~> 1.95"
  spec.add_dependency "abstract-synthesizer", "~> 0.0.14"
  spec.add_dependency "terraform-synthesizer", "~> 0.0.27"
  spec.add_dependency "dry-types", "~> 1.7"
  spec.add_dependency "dry-struct", "~> 1.6"
  spec.add_dependency "dry-validation", "~> 1.10"
  spec.add_dependency "parallel", "~> 1.24"
  spec.metadata['rubygems_mfa_required'] = 'true'
end
