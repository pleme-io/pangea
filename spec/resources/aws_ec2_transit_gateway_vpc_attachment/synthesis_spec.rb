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
require 'pangea/resources/aws_ec2_transit_gateway_vpc_attachment/resource'

RSpec.describe "aws_ec2_transit_gateway_vpc_attachment synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with required attributes" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway_vpc_attachment(:test, {
          transit_gateway_id: "tgw-12345678",
          vpc_id: "vpc-12345678",
          subnet_ids: ["subnet-11111111", "subnet-22222222"],
          tags: { Name: "test-attachment" }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_ec2_transit_gateway_vpc_attachment")
      expect(result["resource"]["aws_ec2_transit_gateway_vpc_attachment"]).to have_key("test")

      attach_config = result["resource"]["aws_ec2_transit_gateway_vpc_attachment"]["test"]
      expect(attach_config["transit_gateway_id"]).to eq("tgw-12345678")
      expect(attach_config["vpc_id"]).to eq("vpc-12345678")
      expect(attach_config["subnet_ids"]).to eq(["subnet-11111111", "subnet-22222222"])
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway_vpc_attachment(:tagged, {
          transit_gateway_id: "tgw-12345678",
          vpc_id: "vpc-12345678",
          subnet_ids: ["subnet-11111111"],
          tags: { Name: "tagged-attachment", Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      attach_config = result["resource"]["aws_ec2_transit_gateway_vpc_attachment"]["tagged"]

      expect(attach_config).to have_key("tags")
      expect(attach_config["tags"]["Name"]).to eq("tagged-attachment")
      expect(attach_config["tags"]["Environment"]).to eq("production")
    end

    it "supports appliance mode" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway_vpc_attachment(:appliance, {
          transit_gateway_id: "tgw-12345678",
          vpc_id: "vpc-12345678",
          subnet_ids: ["subnet-11111111"],
          appliance_mode_support: "enable",
          tags: { Name: "appliance-mode-attachment" }
        })
      end

      result = synthesizer.synthesis
      attach_config = result["resource"]["aws_ec2_transit_gateway_vpc_attachment"]["appliance"]

      expect(attach_config["appliance_mode_support"]).to eq("enable")
    end

    it "supports DNS support" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway_vpc_attachment(:dns, {
          transit_gateway_id: "tgw-12345678",
          vpc_id: "vpc-12345678",
          subnet_ids: ["subnet-11111111"],
          dns_support: "enable",
          tags: { Name: "dns-enabled-attachment" }
        })
      end

      result = synthesizer.synthesis
      attach_config = result["resource"]["aws_ec2_transit_gateway_vpc_attachment"]["dns"]

      expect(attach_config["dns_support"]).to eq("enable")
    end

    it "supports IPv6" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway_vpc_attachment(:ipv6, {
          transit_gateway_id: "tgw-12345678",
          vpc_id: "vpc-12345678",
          subnet_ids: ["subnet-11111111"],
          ipv6_support: "enable",
          tags: { Name: "ipv6-attachment" }
        })
      end

      result = synthesizer.synthesis
      attach_config = result["resource"]["aws_ec2_transit_gateway_vpc_attachment"]["ipv6"]

      expect(attach_config["ipv6_support"]).to eq("enable")
    end

    it "supports custom route table settings" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway_vpc_attachment(:custom_rt, {
          transit_gateway_id: "tgw-12345678",
          vpc_id: "vpc-12345678",
          subnet_ids: ["subnet-11111111"],
          transit_gateway_default_route_table_association: false,
          transit_gateway_default_route_table_propagation: false,
          tags: { Name: "custom-rt-attachment" }
        })
      end

      result = synthesizer.synthesis
      attach_config = result["resource"]["aws_ec2_transit_gateway_vpc_attachment"]["custom_rt"]

      expect(attach_config["transit_gateway_default_route_table_association"]).to eq(false)
      expect(attach_config["transit_gateway_default_route_table_propagation"]).to eq(false)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway_vpc_attachment(:test, {
          transit_gateway_id: "tgw-12345678",
          vpc_id: "vpc-12345678",
          subnet_ids: ["subnet-11111111"]
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_ec2_transit_gateway_vpc_attachment"]).to be_a(Hash)
      expect(result["resource"]["aws_ec2_transit_gateway_vpc_attachment"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      attach_config = result["resource"]["aws_ec2_transit_gateway_vpc_attachment"]["test"]
      expect(attach_config).to have_key("transit_gateway_id")
      expect(attach_config).to have_key("vpc_id")
      expect(attach_config).to have_key("subnet_ids")
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ec2_transit_gateway_vpc_attachment(:test_ref, {
          transit_gateway_id: "tgw-12345678",
          vpc_id: "vpc-12345678",
          subnet_ids: ["subnet-11111111"],
          tags: { Name: "test-attachment" }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_ec2_transit_gateway_vpc_attachment.test_ref.id}")
      expect(ref.outputs[:vpc_owner_id]).to eq("${aws_ec2_transit_gateway_vpc_attachment.test_ref.vpc_owner_id}")
    end
  end
end
