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
        %(#{ENV.fetch('HOME', nil)}/.config)
      )
    end

    # return array of paths that can store a configuration
    def default_paths
      p = {}

      EXTENSIONS.each do |ext|
        p[ext] = [] unless p[ext]
        p[ext] << File.join(%(/opt), %(share), %(pangea.#{ext}))
        p[ext] << File.join(%(/etc), %(pangea), %(pangea.#{ext}))
        p[ext].concat(
          Dir.glob(
            File.join(%(/etc/), %(pangea), %(conf.d), %(*.#{ext}))
          )
        )
        p[ext] << File.join(xdg_config_home, %(pangea), %(pangea.#{ext}))
        p[ext].concat(
          Dir.glob(
            File.join(xdg_config_home, %(pangea), %(conf.d), %(*.#{ext}))
          )
        )
      end

      res = []
      EXTENSIONS.each do |ext|
        files = p[ext]
        files.each do |file|
          res << file if File.exist?(file)
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
