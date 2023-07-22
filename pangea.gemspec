# frozen_string_literal: true

lib = File.expand_path(%(lib), __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative %(./lib/pangea/version)

Gem::Specification.new do |spec|
  spec.name                  = %(pangea)
  spec.version               = Pangea::VERSION
  spec.authors               = [%(drzthslnt@gmail.com)]
  spec.email                 = [%(drzthslnt@gmail.com)]
  spec.description           = %(control rest apis declaratively with ruby)
  spec.summary               = %(control rest apis declaratively with ruby)
  spec.homepage              = %(https://github.com/drzln/#{spec.name})
  spec.license               = %(MIT)
  spec.files                 = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  spec.require_paths         = [%(lib)]
  spec.executables           = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.required_ruby_version = %(>= #{`cat .ruby-version`})

  %i[
    rubocop-rspec
    rubocop-rake
    solargraph
    keycutter
    rubocop
    rspec
    rake
    yard
  ].each do |gem|
    spec.add_development_dependency(gem)
  end

  %i[
    terraform-synthesizer
    abstract-synthesizer
    aws-sdk-dynamodb
    tty-progressbar
    tty-option
    tty-table
    tty-color
    tty-box
    toml-rb
  ].each do |gem|
    spec.add_runtime_dependency(gem)
  end

  spec.metadata[%(rubygems_mfa_required)] = %(true)
end
