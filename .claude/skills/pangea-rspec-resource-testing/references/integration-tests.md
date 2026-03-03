# Integration Tests Pattern

**Location**: `spec/resources/{resource_name}/integration_spec.rb`

**Purpose**: Test complex resource interactions and real-world scenarios.

## Template

```ruby
# Copyright 2025 The Pangea Authors
# Licensed under the Apache License, Version 2.0

require 'spec_helper'

RSpec.describe "{resource_name} integration" do
  include Pangea::Resources::{Provider}

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "complete infrastructure stack" do
    it "creates full stack with multiple resources" do
      synthesizer.instance_eval do
        extend Pangea::Resources::{Provider}

        # Build complete infrastructure
        vpc = aws_vpc(:main, { cidr_block: "10.0.0.0/16" })
        subnet = aws_subnet(:web, {
          vpc_id: vpc.id,
          cidr_block: "10.0.1.0/24"
        })
        sg = aws_security_group(:web, {
          vpc_id: vpc.id,
          ingress_rules: [...]
        })
      end

      result = synthesizer.synthesis

      # Validate entire stack
      expect(result[:resource][:aws_vpc]).to be_present
      expect(result[:resource][:aws_subnet]).to be_present
      expect(result[:resource][:aws_security_group]).to be_present
    end
  end
end
```

## When to Create Integration Tests

Integration tests are **optional** but recommended for:

1. **Multi-resource stacks** - VPC + Subnet + Security Group
2. **Cross-provider resources** - AWS + Cloudflare together
3. **Complex dependency chains** - Zone -> Record -> Worker
4. **Production-like configurations** - Real-world infrastructure patterns
