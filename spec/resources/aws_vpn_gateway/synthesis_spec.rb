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
require 'pangea/resources/aws_vpn_gateway/resource'

RSpec.describe "aws_vpn_gateway synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with minimal config" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpn_gateway(:test, {
          tags: { Name: "test-vpn-gateway" }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_vpn_gateway")
      expect(result["resource"]["aws_vpn_gateway"]).to have_key("test")

      vgw_config = result["resource"]["aws_vpn_gateway"]["test"]
      expect(vgw_config["type"]).to eq("ipsec.1")
    end

    it "generates VPN gateway attached to VPC" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpn_gateway(:attached, {
          vpc_id: "vpc-12345678",
          tags: { Name: "attached-vpn-gateway" }
        })
      end

      result = synthesizer.synthesis
      vgw_config = result["resource"]["aws_vpn_gateway"]["attached"]

      expect(vgw_config["vpc_id"]).to eq("vpc-12345678")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpn_gateway(:tagged, {
          vpc_id: "vpc-12345678",
          tags: { Name: "test-vpn-gateway", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      vgw_config = result["resource"]["aws_vpn_gateway"]["tagged"]

      expect(vgw_config).to have_key("tags")
      expect(vgw_config["tags"]["Name"]).to eq("test-vpn-gateway")
      expect(vgw_config["tags"]["Environment"]).to eq("test")
    end

    it "supports custom Amazon-side ASN" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpn_gateway(:custom_asn, {
          vpc_id: "vpc-12345678",
          amazon_side_asn: 64512,
          tags: { Name: "custom-asn-gateway" }
        })
      end

      result = synthesizer.synthesis
      vgw_config = result["resource"]["aws_vpn_gateway"]["custom_asn"]

      expect(vgw_config["amazon_side_asn"]).to eq(64512)
    end

    it "supports specific availability zone" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpn_gateway(:az_specific, {
          vpc_id: "vpc-12345678",
          availability_zone: "us-east-1a",
          tags: { Name: "az-specific-gateway" }
        })
      end

      result = synthesizer.synthesis
      vgw_config = result["resource"]["aws_vpn_gateway"]["az_specific"]

      expect(vgw_config["availability_zone"]).to eq("us-east-1a")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpn_gateway(:test, {
          vpc_id: "vpc-12345678"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_vpn_gateway"]).to be_a(Hash)
      expect(result["resource"]["aws_vpn_gateway"]["test"]).to be_a(Hash)

      # Validate type attribute is present (required for VPN gateway)
      vgw_config = result["resource"]["aws_vpn_gateway"]["test"]
      expect(vgw_config).to have_key("type")
      expect(vgw_config["type"]).to be_a(String)
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_vpn_gateway(:test_ref, {
          vpc_id: "vpc-12345678",
          tags: { Name: "test-vpn-gateway" }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_vpn_gateway.test_ref.id}")
      expect(ref.outputs[:arn]).to eq("${aws_vpn_gateway.test_ref.arn}")
    end
  end
end
