# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/aws_eventbridge_bus/resource'

RSpec.describe "aws_eventbridge_bus synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for a custom event bus" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_bus(:custom_bus, {
          name: "my-custom-bus"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_cloudwatch_event_bus")
      expect(result["resource"]["aws_cloudwatch_event_bus"]).to have_key("custom_bus")

      config = result["resource"]["aws_cloudwatch_event_bus"]["custom_bus"]
      expect(config["event_bus_name"]).to eq("my-custom-bus")
    end

    it "supports partner event source" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_bus(:partner_bus, {
          name: "partner-events",
          event_source_name: "aws.partner/example.com/12345"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_bus"]["partner_bus"]

      expect(config["event_bus_name"]).to eq("partner-events")
      expect(config["event_source_name"]).to eq("aws.partner/example.com/12345")
    end

    it "supports KMS encryption" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_bus(:encrypted_bus, {
          name: "encrypted-bus",
          kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_bus"]["encrypted_bus"]

      expect(config["kms_key_id"]).to eq("arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_bus(:tagged_bus, {
          name: "tagged-bus",
          tags: { Name: "tagged-bus", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_bus"]["tagged_bus"]

      expect(config).to have_key("tags")
    end

    it "supports application-style configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_bus(:app_bus, {
          name: "orders-service",
          tags: {
            Application: "orders",
            Environment: "production",
            Purpose: "EventDriven"
          }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_bus"]["app_bus"]

      expect(config["event_bus_name"]).to eq("orders-service")
    end

    it "supports multi-tenant bus naming" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_bus(:tenant_bus, {
          name: "tenant-abc123",
          tags: {
            TenantId: "abc123",
            Environment: "production",
            Purpose: "MultiTenant"
          }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_cloudwatch_event_bus"]["tenant_bus"]

      expect(config["event_bus_name"]).to eq("tenant-abc123")
    end
  end

  describe "resource reference" do
    it "returns a reference with expected outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_eventbridge_bus(:ref_test, {
          name: "reference-test-bus"
        })
      end

      expect(ref).not_to be_nil
      expect(ref.type).to eq('aws_cloudwatch_event_bus')
      expect(ref.name).to eq(:ref_test)
      expect(ref.outputs[:arn]).to eq("${aws_cloudwatch_event_bus.ref_test.arn}")
      expect(ref.outputs[:id]).to eq("${aws_cloudwatch_event_bus.ref_test.id}")
      expect(ref.outputs[:event_bus_name]).to eq("${aws_cloudwatch_event_bus.ref_test.event_bus_name}")
    end

    it "includes computed properties for custom bus" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_eventbridge_bus(:computed_test, {
          name: "computed-test-bus"
        })
      end

      expect(ref.computed_properties[:is_custom]).to eq(true)
      expect(ref.computed_properties[:is_default]).to eq(false)
      expect(ref.computed_properties[:bus_type]).to eq("custom")
      expect(ref.computed_properties[:max_rules_per_bus]).to eq(300)
    end

    it "includes computed properties for encrypted bus" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_eventbridge_bus(:encrypted_computed_test, {
          name: "encrypted-computed-bus",
          kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678"
        })
      end

      expect(ref.computed_properties[:has_encryption]).to eq(true)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eventbridge_bus(:validation_test, {
          name: "validation-test-bus"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_cloudwatch_event_bus"]).to be_a(Hash)
      expect(result["resource"]["aws_cloudwatch_event_bus"]["validation_test"]).to be_a(Hash)

      # Validate required attributes are present
      config = result["resource"]["aws_cloudwatch_event_bus"]["validation_test"]
      expect(config).to have_key("event_bus_name")
      expect(config["event_bus_name"]).to be_a(String)
    end
  end
end
