# frozen_string_literal: true

require %(pangea/processor)

describe Pangea::Processor do
  let(:synthesizer_double) { instance_double("TerraformSynthesizer", synthesize: nil, synthesis: {}) }
  let(:config_double) { { foo: "bar" } }
  let(:namespace_double) { "test_namespace" }
  let(:s3_client_double) { instance_double("Aws::S3::Client") }

  subject(:processor) do
    described_class.new(
      synthesizer: synthesizer_double,
      config: config_double,
      namespace: namespace_double,
      s3_client: s3_client_double
    )
  end

  before do
    allow(TerraformSynthesizer).to receive(:new).and_return(synthesizer_double)
    allow(Pangea::Config).to receive(:config).and_return(config_double)
    allow(ENV).to receive(:fetch).with("PANGEA_NAMESPACE").and_return(namespace_double)
    allow(Aws::S3::Client).to receive(:new).and_return(s3_client_double)
    allow(File).to receive(:write)
    allow(File).to receive(:read).and_return("{}")
    allow(processor).to receive(:system).and_return(true) # Stub system on the instance
    allow(processor).to receive(:`).and_return("")
    allow(processor).to receive(:puts)
    allow(Dir).to receive(:exist?).and_return(true)
  end

  context "#register_action" do
    it "sets the action if permitted" do
      described_class.register_action(:plan)
      expect(described_class.instance_variable_get(:@action)).to eq(:plan)
    end

    it "does not set the action if not permitted" do
      described_class.register_action(:unpermitted_action)
      expect(described_class.instance_variable_get(:@action)).to be_nil
    end
  end

  context "#synthesizer" do
    it "returns a TerraformSynthesizer instance" do
      expect(described_class.synthesizer).to be_a_kind_of(TerraformSynthesizer)
    end
  end

  context "#config" do
    it "returns symbolized Pangea config" do
      allow(Pangea::Config).to receive(:config).and_return({ "foo" => "bar" })
      expect(described_class.config).to eq({ foo: "bar" })
    end
  end

  context "#namespace" do
    it "returns the PANGEA_NAMESPACE environment variable" do
      expect(described_class.namespace).to eq("test_namespace")
    end
  end

  context "#bin" do
    it "returns 'tofu'" do
      expect(described_class.bin).to eq("tofu")
    end
  end

  context "#template" do
    it "synthesizes and writes the template" do
      allow(processor).to receive(:namespace_config).and_return({ state: { config: { lock: "lock", bucket: "bucket", region: "region" } } })
      expect(synthesizer_double).to receive(:synthesize).twice # once for block, once for backend
      expect(File).to receive(:write).with(anything, String)

      processor.template("my_template") do
        # dummy block
      end
    end

    it "runs tofu init if .terraform.lock.hcl does not exist" do
      allow(File).to receive(:exist?).and_return(false)
      allow(processor).to receive(:namespace_config).and_return({ state: { config: { lock: "lock", bucket: "bucket", region: "region" } } })
      expect(processor).to receive(:system).with(/tofu init/).and_return(true)

      processor.template("my_template") do
        # dummy block
      end
    end

    it "runs tofu apply when action is apply" do
      processor.register_action(:apply)
      allow(processor).to receive(:namespace_config).and_return({ state: { config: { lock: "lock", bucket: "bucket", region: "region" } } })
      expect(processor).to receive(:system).with(/tofu apply/).and_return(true)

      processor.template("my_template") do
        # dummy block
      end
    end

    it "runs tofu plan when action is plan" do
      processor.register_action(:plan)
      allow(processor).to receive(:namespace_config).and_return({ state: { config: { lock: "lock", bucket: "bucket", region: "region" } } })
      expect(processor).to receive(:system).with(/tofu plan/).and_return(true)

      processor.template("my_template") do
        # dummy block
      end
    end

    it "runs tofu destroy when action is destroy" do
      processor.register_action(:destroy)
      allow(processor).to receive(:namespace_config).and_return({ state: { config: { lock: "lock", bucket: "bucket", region: "region" } } })
      expect(processor).to receive(:system).with(/tofu destroy/).and_return(true)

      processor.template("my_template") do
        # dummy block
      end
    end

    it "prints template when action is show" do
      processor.register_action(:show)
      allow(processor).to receive(:namespace_config).and_return({ state: { config: { lock: "lock", bucket: "bucket", region: "region" } } })
      allow(File).to receive(:read).and_return("{}")
      expect(processor).to receive(:puts).with(JSON.pretty_generate({}))

      processor.template("my_template") do
        # dummy block
      end
    end
  end
end
