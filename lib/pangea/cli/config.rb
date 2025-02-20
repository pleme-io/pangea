require %(pangea/synthesizer/config)
require %(pangea/cli/constants)

module Config
  class << self
    include Constants

    def synthesizer
      @synthesizer ||= ConfigSynthesizer.new
    end

    def xdg_config_home
      ENV.fetch(
        %(XDG_CONFIG_HOME),
        %(#{Dir.home}/.config)
      )
    end

    # return array of paths that can store a configuration
    def default_paths
      paths = {}

      # configuration files to look for
      EXTENSIONS.each do |ext|
        paths[ext] = [] unless paths[ext]

        ###############################
        # system level configuration
        ###############################

        paths[ext] << File.join(%(/etc), %(pangea), %(pangea.#{ext}))
        paths[ext].concat(
          Dir.glob(
            File.join(%(/etc/), %(pangea), %(conf.d), %(*.#{ext}))
          )
        )

        # end system level configuration

        ###############################
        # home configuration
        ###############################

        paths[ext] << File.join(xdg_config_home, %(pangea), %(pangea.#{ext}))
        paths[ext].concat(
          Dir.glob(
            File.join(xdg_config_home, %(pangea), %(conf.d), %(*.#{ext}))
          )
        )

        # end home configuration

        ###############################
        # local configuration
        ###############################

        paths[ext] << %(pangea.#{ext})
        paths[ext] << Dir.glob(
          File.join(
            %(pangea),
            %(conf.d),
            %(*.#{ext})
          )
        )

        # end local configuration
      end

      # only return existing files
      res = []
      EXTENSIONS.each do |ext|
        files = paths[ext]
        files.each do |file|
          res << file if File.exist?(file.to_s)
        end
      end

      res
    end

    # read file paths and run configuration parsers
    # then appropriately merge configurations
    def resolve_configurations(ignore_default_paths: false, extra_paths: [])
      paths = if ignore_default_paths
                extra_paths
              else
                default_paths.concat(extra_paths)
              end
      paths.each do |path|
        parted  = path.split(%(.))
        ext     = parted[-1]
        _base   = parted[0]

        synthesizer.synthesize(File.read(path), ext)
      end
      synthesizer.synthesis
    end
  end
end
