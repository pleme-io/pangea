# frozen_string_literal: true

lib = File.expand_path(%(lib), __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative %(lib/pangea/version)

Gem::Specification.new do |spec|
  spec.name                  = %(pangea)
  spec.version               = Pangea::VERSION
  spec.authors               = [%(drzthslnt@gmail.com)]
  spec.email                 = [%(drzthslnt@gmail.com)]
  spec.description           = %(control rest apis declaratively with ruby)
  spec.summary               = %(control rest apis declaratively with ruby)
  spec.homepage              = %(https://github.com/drzln/#{spec.name})
  spec.license               = %(MIT)
  spec.require_paths         = [%(lib)]
  spec.executables << %(pangea)
  spec.required_ruby_version = %(>=3.3.0)

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  %w[
    rake
    rspec
    debug
    rubocop
    ruby-lsp
    rubocop-rake
    rubocop-rspec
    debug_inspector
  ].each do |dep|
    spec.add_development_dependency dep
  end

  %w[
    rexml
    bundler
    toml-rb
    tty-box
    tty-color
    tty-table
    tty-option
    aws-sdk-s3
    bigdecimal
    tty-progressbar
    aws-sdk-dynamodb
    abstract-synthesizer
    terraform-synthesizer
  ].each do |dep|
    spec.add_dependency dep
  end
  spec.metadata['rubygems_mfa_required'] = 'true'
end
