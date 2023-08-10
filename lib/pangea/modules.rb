###############################################################################
# modules
# module for handling pangea modules
# pangea modules are execution units
# for terraform code.
###############################################################################

module PangeaModule
  BASE_DIR = File.join(
    Dir.home,
    %(.pangea)
  )

  CACHE_DIR = File.join(
    BASE_DIR,
    %(cache)
  )

  RUBIES_DIR = File.join(
    BASE_DIR,
    %(rubies)
  )

  RUBIES_DIR = File.join(
    BASE_DIR,
    %(rubies)
  )

  class << self
    # entrypoint for module processing
    def process(mod); end
  end
end

# end modules
