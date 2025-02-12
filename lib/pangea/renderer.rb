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

  def artifact_json
    File.join(infra_dir, %(artifact.json))
  end

  def pretty(content)
    JSON.pretty_generate(content)
  end

  def run
    system %(mkdir -p #{infra_dir}) unless Dir.exist?(infra_dir)
    # system %(cd #{infra_dir} && #{BIN} init -json)
    synthesizer.synthesize do
      resource :aws_vpc, :foo do
        cidr_block %(10.0.0.0/16)
        tags(Name: :foo)
      end
    end
    puts pretty(synthesizer.synthesis)
    File.write(artifact_json, JSON[synthesizer.synthesis])
  end
end

Renderer.new.run
