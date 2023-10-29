###############################################################################
# modules
# module for handling pangea modules
# pangea modules are execution units
# for terraform code.
###############################################################################

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
    def rbenv_installed?
      `which rbenv`.strip != ''
    end

    def rbenv_install(_version)
      system %(mkdir -p #{VERSIONS_DIR}) unless Dir.exist?(VERSIONS_DIR)
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

  SECTIONS = %i[
    lib
    src
  ].freeze

  class << self
    # entrypoint for module processing
    def process(mod)
      exit 1 unless mod.fetch(:sandboxed, false)
    end
  end
end

# end modules
