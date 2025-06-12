# a renderer takes an artifact.json and implements
# it against a rest api, then potentially runs
# packaged checks and verifications.
# it also exports values into state for the
# child renderer to pick up on

require %(terraform-synthesizer)
require %(pangea/modcache)
require %(pangea/config)
require %(pangea/utils)
require %(aws-sdk-s3)
require %(digest)
require %(json)

module Pangea
  class DirectoryRenderer
    BIN = %(tofu).freeze

    def home_dir
      %(#{Dir.home}/.pangea)
    end

    def infra_dir
      %(#{home_dir}/infra)
    end

    def init_dir
      %(#{infra_dir}/init)
    end

    def artifact_json
      File.join(init_dir, %(artifact.tf.json))
    end

    def pretty(content)
      JSON.pretty_generate(content)
    end

    def create_prepped_state_directory(dir, synthesis)
      system %(mkdir -p #{dir}) unless Dir.exist?(dir)
      File.write(File.join(dir, %(artifact.tf.json)), JSON[synthesis])
      system %(cd #{dir} && #{BIN} init -json) unless Dir.exist?(File.join(dir, %(.terraform)))
      true
    end

    def resource(dir)
      JSON[File.read(File.join(dir, %(artifact.tf.json)))]
    end

    def state(dir)
      pretty(JSON[File.read(File.join(dir, %(terraform.tfstate)))])
    end

    def plan(dir)
      pretty(JSON[File.read(File.join(dir, %(plan.json)))])
    end

    # component is a single resource wrapped in state
    # with available attributes
    def render_component(&block)
      synthesizer.synthesize(&block)
      resource_type = synthesizer.synthesis[:resource].keys[0]
      resource_name = synthesizer.synthesis[:resource][synthesizer.synthesis[:resource].keys[0]].keys[0]
      dir = File.join(init_dir, resource_type.to_s, resource_name.to_s)
      create_prepped_state_directory(dir, synthesizer.synthesis)
      system %(cd #{dir} && #{BIN} show -json tfplan > plan.json)
      system %(cd #{dir} && #{BIN} apply -auto-approve)

      synthesizer.clear_synthesis!

      {
        resource: resource(dir),
        state: state(dir),
        plan: plan(dir)
      }
    end
  end

  class S3Renderer
    class << self
      def synthesizer
        @synthesizer ||= TerraformSynthesizer.new
      end
    end

    # BIN = %(tofu).freeze

    # attr_reader :namespace

    # def initialize
    #   raise ArgumentError, 'provide PANGEA_NAMESPACE ENVVAR' if ENV.fetch('PANGEA_NAMESPACE').nil?
    #
    #   @namespace = ENV.fetch('PANGEA_NAMESPACE', nil)
    # end

    # def config
    #   @config ||= Pangea::Utils.symbolize(
    #     Pangea::Config.config
    #   )
    # end

    # def s3
    #   @s3 = Aws::S3::Client.new
    # end

    # def verify_state(state)
    #   raise Argumenterror, 'must have a bucket' unless state[:config][:bucket]
    #   raise Argumenterror, 'must have a region' unless state[:config][:region]
    #   raise Argumenterror, 'must have a lock' unless state[:config][:lock]
    # end

    # def pangea_home
    #   %(#{Dir.home}/.pangea/#{namespace})
    # end

    # def bin
    #   %(tofu)
    # end

    # def selected_namespace_configuration
    #   sns = ''
    #   config[:namespaces].each_key do |ns|
    #     sns = config[:namespaces][ns] if ns.to_s.eql?(namespace.to_s)
    #   end
    #   @selected_namespace_configuration ||= sns
    # end

    # render things in a resource context
    # without using terraform modules
    # def state(name, &block)
    #   if block.nil?
    #     File.write(File.join(local_cache, 'main.tf.json'), JSON[{}])
    #     system("cd #{local_cache} && #{bin} init -input=false")
    #     system("cd #{local_cache} && #{bin} plan")
    #     system("cd #{local_cache} && #{bin} apply -auto-approve")
    #     return {}
    #   end
    #   S3Renderer.synthesizer.synthesize(&block)
    #   synth = Pangea::Utils.symbolize(S3Renderer.synthesizer.synthesis)
    #   prefix = "#{name}/pangea"
    #   local_cache = File.join(pangea_home, prefix)
    #   `mkdir -p #{local_cache}` unless Dir.exist?(local_cache)
    #   sns = selected_namespace_configuration
    #   verify_state(sns[:state])
    #
    #   # apply state configuration
    #   unless synth[:terraform]
    #     S3Renderer.synthesizer.synthesize do
    #       terraform do
    #         backend(
    #           s3: {
    #             key: prefix,
    #             dynamodb_table: sns[:state][:config][:lock].to_s,
    #             bucket: sns[:state][:config][:bucket].to_s,
    #             region: sns[:state][:config][:region].to_s,
    #             encrypt: true
    #           }
    #         )
    #       end
    #     end
    #   end
    #
    #   File.write(File.join(local_cache, 'main.tf.json'), JSON[S3Renderer.synthesizer.synthesis])
    #   template = Pangea::Utils.symbolize(JSON[File.read(File.join(local_cache, 'main.tf.json'))])
    #   system("cd #{local_cache} && #{bin} init -input=false")
    #   system("cd #{local_cache} && #{bin} plan")
    #   system("cd #{local_cache} && #{bin} apply -auto-approve")
    #   # puts s3.list_objects_v2(bucket: sns[:state][:config][:bucket], prefix: prefix).contents.map(&:key)
    #   { template: template }
    # end

    # def state_keys
    #   sns = selected_namespace_configuration
    # end

    # def state; end

    # def render_component(template)
    #   mod = 'stump'
    #   sns = ''
    #   config[:namespaces].each_key do |ns|
    #     sns = config[:namespaces][ns] if ns.to_s.eql?(namespace.to_s)
    #   end
    #
    #   unless sns[:state][:type].to_s.eql?('s3')
    #     raise ArgumentError,
    #           'state type must be s3 '
    #   end
    #
    #   if sns.nil? || sns.empty?
    #     raise ArgumentError,
    #           "namespace #{namespace} not found in #{Pangea::Utils.pretty(config)}"
    #   end
    #
    #   synthesizer.synthesize(template)
    #   syn = Pangea::Utils.symbolize(synthesizer.synthesis)
    #   raise ArgumentError, 'must provide at least one resource' if syn[:resource].nil?
    #
    #   resource_name = syn[:resource].keys[0]
    #   virtual_name  = syn[:resource][syn[:resource].keys[0]].keys[0]
    #
    #   synthesizer.synthesize do
    #     provider do
    #       aws(region: sns[:state][:config][:region].to_s)
    #     end
    #     variable do
    #       name(type: 'string', description: 'the module name')
    #     end
    #   end
    #
    #   synthesizer.synthesize do
    #     terraform do
    #       backend(
    #         s3: {
    #           key: "#{sns[:name]}/#{mod}/#{resource_name}/#{virtual_name}/module",
    #           dynamodb_table: sns[:state][:config][:lock].to_s,
    #           bucket: sns[:state][:config][:bucket].to_s,
    #           region: sns[:state][:config][:region].to_s,
    #           encrypt: true
    #         }
    #       )
    #     end
    #   end
    #
    #   # modcache_address = "#{sns[:name]}/#{mod}/#{resource_name}/#{virtual_name}/module"
    #
    #   # create the modcache directory
    #   modcache = Pangea::ModCache.new(
    #     sns[:name],
    #     mod,
    #     resource_name,
    #     virtual_name
    #   )
    #   # place the internal module
    #   modcache.place_internal_module(syn)
    #   modcache.place_caller_template
    #
    #   Pangea::Utils.symbolize(synthesizer.synthesis)
    # end
  end
end
