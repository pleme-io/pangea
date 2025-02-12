# a renderer takes an artifact.json and implements
# it against a rest api, then potentially runs
# packaged checks and verifications.
# it also exports values into state for the
# child renderer to pick up on

require %(terraform-synthesizer)
require %(json)

class Renderer
  BIN = %(tofu)

  def synthesizer
    @synthesizer ||= TerraformSynthesizer.new
  end

  def home_dir
    %(#{ENV.fetch(%(HOME), nil)}/.pangea)
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

  def create_prepped_state_directory(dir)
    system %(mkdir -p #{dir}) unless Dir.exist?(dir)
    synthesizer.synthesize do
      resource :aws_vpc, :foo do
        cidr_block %(10.0.0.0/16)
        tags(Name: :foo)
      end
    end
    File.write(File.join(dir, %(artifact.tf.json)), JSON[synthesizer.synthesis])
    system %(cd #{dir} && #{BIN} init -json) unless Dir.exist?(File.join(dir, %(.terraform)))
    true
  end

  def run
    test_cycle
  end

  def test_cycle
    dir = %(#{init_dir})
    synthesizer.synthesize do
      resource :aws_vpc, :foo do
        cidr_block %(10.0.0.0/16)
        tags(Name: :foo)
      end
    end
    resource_type = synthesizer.synthesis[:resource].keys[0]
    resource_name = synthesizer.synthesis[:resource][synthesizer.synthesis[:resource].keys[0]].keys[0]
    puts pretty(resource_type)
    puts pretty(resource_name)
    dir = File.join(init_dir, resource_type.to_s, resource_name.to_s)
    create_prepped_state_directory(dir)
    # system %(cd #{init_dir} && #{BIN} plan)
    # system %(cd #{init_dir} && #{BIN} apply -auto-approve)
    # system %(cd #{init_dir} && #{BIN} destroy -auto-approve)
  end
end

Renderer.new.run
