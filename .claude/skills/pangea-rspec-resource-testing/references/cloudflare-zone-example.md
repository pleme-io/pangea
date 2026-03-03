# Complete Example: Cloudflare Zone Test Suite

## Type Validation Tests

**File**: `spec/resources/cloudflare/types/zone_spec.rb`

```ruby
RSpec.describe Pangea::Resources::Cloudflare::Types::ZoneAttributes do
  it "creates valid zone" do
    attrs = described_class.new(zone: "example.com")
    expect(attrs.zone).to eq("example.com")
    expect(attrs.plan).to eq("free")
  end

  it "computes is_subdomain?" do
    root = described_class.new(zone: "example.com")
    subdomain = described_class.new(zone: "www.example.com")

    expect(root.is_subdomain?).to be false
    expect(subdomain.is_subdomain?).to be true
  end
end
```

## Synthesis Tests (REQUIRED)

**File**: `spec/resources/cloudflare_zone/synthesis_spec.rb`

```ruby
RSpec.describe 'cloudflare_zone synthesis' do
  include Pangea::Resources::Cloudflare
  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes basic zone' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_zone(:test, { zone: "example.com" })
    end

    result = synthesizer.synthesis
    zone = result[:resource][:cloudflare_zone][:test]

    expect(zone).to include(
      zone: "example.com",
      plan: "free",
      jump_start: false
    )
  end
end
```

## Key Points

1. **Type tests** verify Dry::Struct attributes and computed properties
2. **Synthesis tests** verify actual Terraform JSON generation
3. Both are needed for complete coverage
4. Synthesis tests are **MANDATORY** - type tests alone are incomplete
