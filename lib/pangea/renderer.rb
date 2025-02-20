# a renderer takes an artifact.json and implements
# it against a rest api, then potentially runs
# packaged checks and verifications.
# it also exports values into state for the
# child renderer to pick up on

require %(terraform-synthesizer)
require %(json)
require %(digest)

class Renderer
  BIN = %(tofu).freeze

  def synthesizer
    @synthesizer ||= TerraformSynthesizer.new
  end

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
    system %(cd #{dir} && #{BIN} show -json tfplan > plan.json)
    system %(cd #{dir} && #{BIN} apply -auto-approve)
    synthesizer.clear_synthesis!
    {
      resource: resource(dir),
      state: state(dir),
      plan: plan(dir)
    }
  end

  def test_render
    foo = render_component do
      resource :aws_vpc, :foo do
        cidr_block %(10.0.0.0/16)
        tags(Name: :foo)
      end
    end
    bar = render_component do
      resource :aws_vpc, :bar do
        cidr_block %(10.1.0.0/16)
        tags(Name: :bar)
      end
    end
    puts foo[:resource]
    puts bar[:resource]
    # puts results[:plan]
    # puts results[:state]
  end

  def run
    puts test_render
  end

  # def test_cycle
  #   synthesizer.synthesize do
  #     resource :aws_vpc, :foo do
  #       cidr_block %(10.0.0.0/16)
  #       tags(Name: :foo)
  #     end
  #   end
  #   resource_type = synthesizer.synthesis[:resource].keys[0]
  #   resource_name = synthesizer.synthesis[:resource][synthesizer.synthesis[:resource].keys[0]].keys[0]
  #   puts pretty(resource_type)
  #   puts pretty(resource_name)
  #   dir = File.join(init_dir, resource_type.to_s, resource_name.to_s)
  #   create_prepped_state_directory(dir, synthesizer.synthesis)
  #   system %(cd #{dir} && #{BIN} apply -auto-approve)
  #   synthesizer.clear_synthesis!
  #   synthesizer.synthesize do
  #     resource :aws_vpc, :bar do
  #       cidr_block %(10.1.0.0/16)
  #       tags(Name: :bar)
  #     end
  #   end
  #   puts synthesizer.synthesis
  #   resource_type = synthesizer.synthesis[:resource].keys[0]
  #   resource_name = synthesizer.synthesis[:resource][synthesizer.synthesis[:resource].keys[0]].keys[0]
  #   puts pretty(resource_type)
  #   puts pretty(resource_name)
  #   dir = File.join(init_dir, resource_type.to_s, resource_name.to_s)
  #   puts dir
  #   create_prepped_state_directory(dir, synthesizer.synthesis)
  #   system %(cd #{dir} && #{BIN} plan -out=tfplan)
  #   system %(cd #{dir} && #{BIN} show -json tfplan > plan.json)
  #   system %(cd #{dir} && #{BIN} apply -auto-approve)
  #   puts resource(dir)
  #   puts state(dir)
  #   puts plan(dir)
  #   # system %(cd #{init_dir} && #{BIN} destroy -auto-approve)
  # end
end

Renderer.new.run
