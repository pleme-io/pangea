---
name: pangea-rspec-resource-testing
description: >-
  Creates RSpec tests for Pangea resource functions with terraform-synthesizer validation.
  Use when adding cloud resources to Pangea, writing resource tests, or validating
  Terraform synthesis. Covers type validation, synthesis tests, and integration patterns
  for AWS/GCP/Azure/Cloudflare/Hetzner resources.
allowed-tools: Read, Write, Edit, Bash
metadata:
  version: "1.0.0"
  last_verified: "2025-12-27"
  research_version: "2025-12-27"
  domain_keywords:
    - "terraform-synthesis"
    - "rspec-testing"
    - "pangea-resources"
    - "infrastructure-as-code"
    - "dry-types-validation"
    - "cloud-infrastructure"
---

# Pangea RSpec Resource Function Testing

You are an expert at creating comprehensive RSpec tests for Pangea resource functions.

## Testing Strategy

Pangea resources require THREE levels of testing:

| Level | Purpose | Required |
|-------|---------|----------|
| Type Validation | Test Dry::Struct attributes | Yes |
| Terraform Synthesis | Test actual Terraform JSON | **CRITICAL** |
| Integration | Test resource composition | Optional |

**CRITICAL**: All tests must use terraform-synthesizer to validate that resources actually generate correct Terraform JSON. Tests that only validate types are incomplete.

## Test File Organization

```
spec/resources/{resource_name}/
  synthesis_spec.rb           # Terraform synthesis tests (REQUIRED)
  integration_spec.rb         # Resource composition tests (optional)

spec/resources/{provider}/types/
  {resource_name}_spec.rb     # Type validation tests (for types.rb)
```

## Quick Reference: Test Templates

### Type Validation Tests

**Location**: `spec/resources/{provider}/types/{resource_name}_spec.rb`

**Details**: See `{baseDir}/references/type-validation-tests.md`

```ruby
# frozen_string_literal: true
require_relative '../../../spec_helper'

RSpec.describe Pangea::Resources::{Provider}::Types::{ResourceName}Attributes do
  it "creates valid resource with required attributes" do
    attrs = described_class.new(required_field: "value")
    expect(attrs.required_field).to eq("value")
    expect(attrs.optional_field).to eq("default_value")
  end

  it "rejects invalid values" do
    expect {
      described_class.new(required_field: "invalid!")
    }.to raise_error(Dry::Types::ConstraintError)
  end
end
```

### Terraform Synthesis Tests (CRITICAL)

**Location**: `spec/resources/{resource_name}/synthesis_spec.rb`

**Details**: See `{baseDir}/references/synthesis-tests.md`

```ruby
# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/{resource_name}/resource'
require 'pangea/resources/{resource_name}/types'

RSpec.describe '{resource_name} synthesis' do
  include Pangea::Resources::{Provider}
  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes basic resource with defaults' do
    synthesizer.instance_eval do
      extend Pangea::Resources::{Provider}
      {resource_function}(:test, { required_field: "value" })
    end

    result = synthesizer.synthesis
    resource = result[:resource][:{terraform_resource_type}][:test]

    expect(resource).to include(required_field: "value")
    expect(resource).not_to have_key(:omitted_field)
  end
end
```

### Integration Tests (Optional)

**Location**: `spec/resources/{resource_name}/integration_spec.rb`

**Details**: See `{baseDir}/references/integration-tests.md`

## Key Testing Principles

### 1. Always Test Synthesis

| Pattern | Quality |
|---------|---------|
| Only testing types (no synthesizer) | BAD |
| Testing synthesis + verifying Terraform JSON | GOOD |

### 2. Test Generated Terraform Structure

```ruby
result = synthesizer.synthesis
resource = result[:resource][:cloudflare_record][:www]

expect(resource).to include(zone_id: expected_zone_id, name: "www", type: "A")
expect(resource[:ttl]).to eq(1)                    # Defaults applied
expect(resource).not_to have_key(:priority)        # Optional omitted
```

### 3. Test Resource References

```ruby
ref = synthesizer.instance_eval do
  cloudflare_zone(:test, { zone: "example.com" })
end

expect(ref.id).to eq("${cloudflare_zone.test.id}")
```

### 4. Test Resource Composition

```ruby
synthesizer.instance_eval do
  zone = cloudflare_zone(:main, { zone: "example.com" })
  cloudflare_record(:www, { zone_id: zone.id, name: "www", type: "A", value: "192.0.2.1" })
end

result = synthesizer.synthesis
record = result[:resource][:cloudflare_record][:www]
expect(record[:zone_id]).to eq("${cloudflare_zone.main.id}")
```

**More patterns**: See `{baseDir}/references/common-patterns.md`

## Anti-Patterns to Avoid

| Anti-Pattern | Problem |
|--------------|---------|
| Testing only types without synthesis | Doesn't verify Terraform generation |
| Not using `instance_eval` | Resource function not in synthesizer context |
| Not checking generated Terraform structure | Missing validation of output |

**BAD**:
```ruby
it "creates zone" do
  attrs = ZoneAttributes.new(zone: "example.com")  # INCOMPLETE
  expect(attrs.zone).to eq("example.com")
end
```

**GOOD**:
```ruby
it "synthesizes zone" do
  synthesizer.instance_eval do
    extend Pangea::Resources::Cloudflare
    cloudflare_zone(:test, { zone: "example.com" })
  end
  result = synthesizer.synthesis
  zone = result[:resource][:cloudflare_zone][:test]
  expect(zone[:zone]).to eq("example.com")
  expect(zone[:plan]).to eq("free")  # Verify default
end
```

## Checklist

When creating tests for a new resource, ensure:

- [ ] Type validation tests cover all attributes
- [ ] Type validation tests cover all validation rules
- [ ] Type validation tests cover computed properties
- [ ] **Synthesis tests actually call terraform-synthesizer**
- [ ] Synthesis tests verify generated Terraform structure
- [ ] Synthesis tests verify defaults appear in Terraform
- [ ] Synthesis tests verify optional fields are omitted when nil
- [ ] Synthesis tests verify resource references work
- [ ] Synthesis tests verify resource composition
- [ ] Real-world usage scenarios are tested

## Troubleshooting Quick Reference

| Issue | Solution |
|-------|----------|
| Hash vs Array for nested blocks | Single=Hash, Multiple=Array |
| Field appears when shouldn't | Add conditional: `field value if value` |
| Symbol vs String key error | Use `{ "Key" => "value" }` not `{ Key: "value" }` |
| "invalid for TerraformSynthesizer" | Add `require` for referenced resources |
| Missing required attribute | Check types.rb for required fields |
| SimpleCov coverage failure | Disable minimum or set `SKIP_COVERAGE_CHECK` |

**Full troubleshooting**: See `{baseDir}/references/troubleshooting.md`

**Debugging guide**: See `{baseDir}/references/debugging.md`

## When to Use This Skill

Use this skill when:
1. Creating a new Pangea resource function
2. Adding tests to an existing resource
3. Updating tests after resource changes
4. Reviewing test coverage for resources
5. User asks: "create tests for {resource_name}"
6. User asks: "add synthesis tests"
7. User asks: "test the Terraform generation"

## Testing Workflow

1. **Create Type Validation Tests First** - Test Dry::Struct attributes
2. **Create Synthesis Tests (CRITICAL)** - Test terraform-synthesizer output
3. **Create Integration Tests (Optional)** - Test multi-resource scenarios
4. **Run Tests**: `rspec spec/resources/{resource_name}/`

## Reference Files

| Topic | Location |
|-------|----------|
| Type validation test template | `{baseDir}/references/type-validation-tests.md` |
| Synthesis test template | `{baseDir}/references/synthesis-tests.md` |
| Integration test template | `{baseDir}/references/integration-tests.md` |
| Common testing patterns | `{baseDir}/references/common-patterns.md` |
| Troubleshooting guide | `{baseDir}/references/troubleshooting.md` |
| Debugging guide | `{baseDir}/references/debugging.md` |
| Complete example (Cloudflare Zone) | `{baseDir}/references/cloudflare-zone-example.md` |

## Output

When asked to create tests, generate all test files following these patterns. Include:
- Complete test file with copyright header
- Appropriate describe blocks
- Mix of positive and negative test cases
- Real-world usage examples
- Clear expectations and assertions

**MANDATORY**: Synthesis tests using terraform-synthesizer are required for validating resource functions.
