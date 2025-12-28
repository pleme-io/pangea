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
require 'pangea/resources/aws_route53_zone/resource'

RSpec.describe "aws_route53_zone synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for public zone" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_zone(:test, {
          name: "example.com",
          comment: "Test public zone"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_route53_zone")
      expect(result["resource"]["aws_route53_zone"]).to have_key("test")

      zone_config = result["resource"]["aws_route53_zone"]["test"]
      expect(zone_config["name"]).to eq("example.com")
      expect(zone_config["comment"]).to eq("Test public zone")
    end

    it "generates terraform with tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_zone(:test, {
          name: "example.com",
          tags: { Name: "test-zone", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      zone_config = result["resource"]["aws_route53_zone"]["test"]

      expect(zone_config).to have_key("tags")
      expect(zone_config["tags"]["Name"]).to eq("test-zone")
      expect(zone_config["tags"]["Environment"]).to eq("test")
    end

    it "generates terraform for private zone with VPC" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_zone(:test, {
          name: "internal.example.com",
          vpc: [{ vpc_id: "vpc-12345678", vpc_region: "us-east-1" }]
        })
      end

      result = synthesizer.synthesis
      zone_config = result["resource"]["aws_route53_zone"]["test"]

      expect(zone_config["name"]).to eq("internal.example.com")
      expect(zone_config).to have_key("vpc")
    end

    it "supports delegation set configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_zone(:test, {
          name: "delegated.example.com",
          delegation_set_id: "N1PA6795SAMPLE"
        })
      end

      result = synthesizer.synthesis
      zone_config = result["resource"]["aws_route53_zone"]["test"]

      expect(zone_config["delegation_set_id"]).to eq("N1PA6795SAMPLE")
    end

    it "supports force_destroy option" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_zone(:test, {
          name: "dev.example.com",
          force_destroy: true
        })
      end

      result = synthesizer.synthesis
      zone_config = result["resource"]["aws_route53_zone"]["test"]

      expect(zone_config["force_destroy"]).to eq(true)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_zone(:test, { name: "example.com" })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_route53_zone"]).to be_a(Hash)
      expect(result["resource"]["aws_route53_zone"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      zone_config = result["resource"]["aws_route53_zone"]["test"]
      expect(zone_config).to have_key("name")
      expect(zone_config["name"]).to be_a(String)
    end
  end

  describe "resource references" do
    it "returns a resource reference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route53_zone(:test, { name: "example.com" })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_route53_zone')
      expect(ref.name).to eq(:test)

      # Verify output references
      expect(ref.outputs[:id]).to eq("${aws_route53_zone.test.id}")
      expect(ref.outputs[:zone_id]).to eq("${aws_route53_zone.test.zone_id}")
      expect(ref.outputs[:arn]).to eq("${aws_route53_zone.test.arn}")
      expect(ref.outputs[:name_servers]).to eq("${aws_route53_zone.test.name_servers}")
    end

    it "provides computed properties for zone type" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route53_zone(:test, { name: "example.com" })
      end

      expect(ref.is_public?).to eq(true)
      expect(ref.is_private?).to eq(false)
      expect(ref.zone_type).to eq("public")
    end

    it "provides computed properties for private zone" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route53_zone(:test, {
          name: "internal.example.com",
          vpc: [{ vpc_id: "vpc-12345678" }]
        })
      end

      expect(ref.is_public?).to eq(false)
      expect(ref.is_private?).to eq(true)
      expect(ref.zone_type).to eq("private")
      expect(ref.vpc_count).to eq(1)
    end

    it "provides domain analysis computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route53_zone(:test, { name: "api.example.com" })
      end

      expect(ref.subdomain?).to eq(true)
      expect(ref.root_domain?).to eq(false)
      expect(ref.top_level_domain).to eq("com")
      expect(ref.parent_domain).to eq("example.com")
    end
  end
end
