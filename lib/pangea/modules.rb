###############################################################################
# modules
# module for handling pangea modules
# pangea modules are execution units
# for terraform code.
###############################################################################

require %(terraform-synthesizer)
require %(bundler)

module PangeaBase
  BASE_DIR = File.join(
    Dir.home,
    %(.pangea)
  )
end

module PangeaRbenv
  include PangeaBase

  BIN = %(rbenv).freeze

  RBENV_DIR = File.join(
    BASE_DIR,
    %(rbenv)
  )

  VERSIONS_DIR = File.join(
    RBENV_DIR,
    %(versions)
  )

  class << self
    def versions_dir
      VERSIONS_DIR
    end

    def rbenv_installed?
      `which rbenv`.strip != ''
    end

    def rbenv_install(version, path)
      system %(mkdir -p #{VERSIONS_DIR}) unless Dir.exist?(VERSIONS_DIR)
      if rbenv_installed? && !Dir.exist?(File.join(path.to_s))
        system [BIN, %(install), version.to_s, path.to_s].join(%( ))
      end
    end
  end
end

module PangeaRubyBuild
  include PangeaBase
  BIN = %(ruby-build).freeze
  RUBY_BUILD_DIR = File.join(
    BASE_DIR,
    %(rbenv)
  )
  class << self
    def ruby_build_installed?
      `which rbenv`.strip != ''
    end

    def ruby_build(version, path)
      system %(mkdir -p #{PangeaRbenv.versions_dir}) unless Dir.exist?(PangeaRbenv.versions_dir)
      system [BIN, version.to_s, path.to_s].join(%( )) if ruby_build_installed? && !Dir.exist?(File.join(path.to_s))
    end

    def gem_install(gem, ruby_version, gem_version, gemset_path)
      gem_path = File.join(gemset_path, %(lib), %(ruby), %(gems), ruby_version.to_s, %(gems), %(#{gem}-#{gem_version}))
      unless Dir.exist?(gem_path)
        gembin = File.join(gemset_path, %(bin), %(gem))
        system [gembin, %(install), gem.to_s.strip, %(-v), gem_version.to_s].join(%( ))
      end
    end

    def bundle_install(mpath, gemset_path)
      @bundlebin = File.join(gemset_path, %(bin), %(bundle))
      bundlehint = File.join(gemset_path, %(bundle_hint))
      unless File.exist?(bundlehint)
        cmd = [
          # %(cd #{mpath} &&),
          %(BUNDLE_GEMFILE=#{File.join(mpath, %(Gemfile))}), @bundlebin,
          %(install)
        ].join(%( ))
        system cmd
        system [%(touch), bundlehint].join(%( ))
      end
    end
  end
end

module PangeaModule
  include PangeaBase

  CACHE_DIR = File.join(
    BASE_DIR,
    %(cache)
  )

  RUBIES_DIR = File.join(
    BASE_DIR,
    %(rubies)
  )

  class << self
    def symbolize(hash)
      JSON[JSON[hash], symbolize_names: true]
    end

    def terraform_synth
      @terraform_synth ||= TerraformSynthesizer.new
    end

    # entrypoint for module processing
    def process(mod)
      mod = symbolize(mod)

      name = mod.fetch(:name)
      data = mod.fetch(:data, {})

      raise ArgumentError, %(name cannot be nil) if name.nil?

      # understanding that module entrypoint loading
      # will work with #{context}-#{name}
      context       = mod.fetch(:context, %(pangea-component))
      require_name  = %(#{context}-#{name})

      require require_name
      render(data)
    end
  end
end

# end modules
