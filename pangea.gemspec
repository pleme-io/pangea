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
  spec.require_paths         = [%(lib)]
  spec.executables << %(pangea)
  spec.required_ruby_version = %(3.6.6)

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  definition = Bundler::Definition.build("Gemfile", "Gemfile.lock", nil)
  runtime_deps = definition.dependencies.select { |dep| dep.groups.include?(:default) }
  runtime_deps.each do |dep|
    spec.add_dependency(dep.name, *dep.requirement.as_list)
  end
end
