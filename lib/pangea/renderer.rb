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
  end
end
