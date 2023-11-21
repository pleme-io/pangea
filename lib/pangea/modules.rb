###############################################################################
# modules
# module for handling pangea modules
# pangea modules are execution units
# for terraform code.
###############################################################################

require %(terraform-synthesizer)

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
        puts [BIN, %(install), version.to_s, path.to_s].join(%( ))
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
      if ruby_build_installed? && !Dir.exist?(File.join(path.to_s))
        puts [BIN, version.to_s, path.to_s].join(%( ))
        system [BIN, version.to_s, path.to_s].join(%( ))
      end
    end

    def gem_install(gem, ruby_version, gem_version, gemset_path)
      gem_path = File.join(gemset_path, %(lib), %(ruby), %(gems), ruby_version.to_s, %(gems), %(#{gem}-#{gem_version}))
      unless Dir.exist?(gem_path)
        gembin = File.join(gemset_path, %(bin), %(gem))
        puts [gembin, %(install), gem.to_s.strip, %(-v), gem_version.to_s].join(%( ))
        system [gembin, %(install), gem.to_s.strip, %(-v), gem_version.to_s].join(%( ))
      end
    end

    def bundle_install(mpath, gemset_path)
      bundlebin = File.join(gemset_path, %(bin), %(bundle))
      bundlehint = File.join(gemset_path, %(bundle_hint))
      unless File.exist?(bundlehint)
        cmd = [
          # %(cd #{mpath} &&),
          %(BUNDLE_GEMFILE=#{File.join(mpath, %(Gemfile))}), bundlebin,
          %(install)
        ].join(%( ))
        puts cmd
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

    SECTIONS = %i[
      lib
      src
    ].freeze

    # entrypoint for module processing
    def process(mod)
      mod = symbolize(mod)
      if mod.fetch(:sandboxed)

        ################################
        # setup ruby environment for module
        ################################

        ruby_version    = mod.fetch(:ruby_version, %(3.1.0))
        bundle_version  = mod.fetch(:ruby_version, %(2.3.3))
        name            = mod.fetch(:name)

        raise ArgumentError, %(name cannot be nil) if name.nil?

        ruby_gemset = mod.fetch(:ruby_gemset, name)

        gemset_path = File.join(
          RUBIES_DIR,
          ruby_version,
          ruby_gemset
        )

        gems_load_path = File.join(
          gemset_path,
          %(gems)
        )

        PangeaRubyBuild.ruby_build(
          ruby_version,
          gemset_path
        )

        PangeaRubyBuild.gem_install(
          %(bundler),
          ruby_version,
          bundle_version,
          gemset_path
        )

        location  = mod.fetch(:location)
        type      = location.fetch(:type)

        if type.to_s.eql?(%(directory))
          mpath = location.fetch(:path)
          PangeaRubyBuild.bundle_install(
            mpath,
            gemset_path
          )
        end

        # end setup ruby environment for module

        ################################
        # run module
        ################################

        # set the $LOAD_PATH to empty to make sure
        # its clean
        # $LOAD_PATH = []

        # $LOAD_PATH.concat(gems_load_path)

        # add ruby gems path to $LOAD_PATH
        # $LOAD_PATH.unshift(File.join())

        SECTIONS.each do |section|
          rfiles = Dir.glob(
            File.join(
              mpath.to_s,
              section.to_s,
              %(**),
              %(*.rb)
            )
          )
          # rdirs = rfiles.map { |file_path| File.dirname(file_path) }
          # rdirs = rdirs.uniq
          rfiles.each do |rfile|
            terraform_synth.synthesize(File.read(rfile))
          end
        end
        puts terraform_synth.synthesis

        # end run module

      end
    end
  end
end

# end modules
