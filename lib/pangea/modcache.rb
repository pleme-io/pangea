# unfortunately, in order to call an opentofu mod/resource combination a file must be created
# represent the resource module and then another file must represent the caller.
# this means temporarily having a folder created for each as we move through mod/resources

module Pangea
  class ModCache
    attr_reader :name,
                :mod,
                :resource,
                :virtual,
                :basedir,
                :modcachedir,
                :address

    def initialize(name, mod, resource, virtual)
      @name     = name
      @mod      = mod
      @resource = resource
      @virtual  = virtual
      @basedir = File.join(Dir.home, '.pangea')
      @modcachedir = File.join(basedir, 'modcache')
      @address = "#{name}/#{mod}/#{resource}/#{virtual}/module"
      @internal_module_file_name = 'internal.tf.json'
    end

    def preflight
      [basedir, modcachedir, File.join(modcachedir, address)].each do |d|
        `mkdir -p #{modcachedir}` unless Dir.exist?(d)
      end
    end

    def place_internal_module(template)
      preflight
      internal_module_path = File.join(
        modcachedir,
        @internal_module_file_name
      )
      File.write(internal_module_path, template)
    end

    def place_caller_template
      internal_module_path = File.join(
        modcachedir,
        @internal_module_file_name
      )
      caller_template = {
        provider: {
          aws: {
            region: 'us-east-1'
          }
        },
        module: {
          "#{name}": {
            source: internal_module_path
          }
        }
      }

      internal_caller_template_path = File.join(
        modcachedir,
        'caller.tf.json'
      )
      File.write(internal_caller_template_path, JSON[caller_template])
    end

    # class << self
    #   def register_module(mod)
    #     @mod = mod
    #   end
    #
    #   def register_name(name)
    #     @name = name
    #   end
    #
    #
    #   def create_directories(dirs); end
    # end
  end
end
