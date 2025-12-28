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
require 'pangea/resources/aws_ec2_transit_gateway/resource'

RSpec.describe "aws_ec2_transit_gateway synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with minimal config" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway(:test, {
          tags: { Name: "test-transit-gateway" }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_ec2_transit_gateway")
      expect(result["resource"]["aws_ec2_transit_gateway"]).to have_key("test")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway(:tagged, {
          tags: { Name: "tagged-tgw", Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      tgw_config = result["resource"]["aws_ec2_transit_gateway"]["tagged"]

      expect(tgw_config).to have_key("tags")
      expect(tgw_config["tags"]["Name"]).to eq("tagged-tgw")
      expect(tgw_config["tags"]["Environment"]).to eq("production")
    end

    it "supports custom Amazon-side ASN" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway(:custom_asn, {
          amazon_side_asn: 64512,
          tags: { Name: "custom-asn-tgw" }
        })
      end

      result = synthesizer.synthesis
      tgw_config = result["resource"]["aws_ec2_transit_gateway"]["custom_asn"]

      expect(tgw_config["amazon_side_asn"]).to eq(64512)
    end

    it "supports auto-accept shared attachments" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway(:auto_accept, {
          auto_accept_shared_attachments: "enable",
          tags: { Name: "auto-accept-tgw" }
        })
      end

      result = synthesizer.synthesis
      tgw_config = result["resource"]["aws_ec2_transit_gateway"]["auto_accept"]

      expect(tgw_config["auto_accept_shared_attachments"]).to eq("enable")
    end

    it "supports default route table association/propagation settings" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway(:route_tables, {
          default_route_table_association: "disable",
          default_route_table_propagation: "disable",
          tags: { Name: "custom-route-tgw" }
        })
      end

      result = synthesizer.synthesis
      tgw_config = result["resource"]["aws_ec2_transit_gateway"]["route_tables"]

      expect(tgw_config["default_route_table_association"]).to eq("disable")
      expect(tgw_config["default_route_table_propagation"]).to eq("disable")
    end

    it "supports description" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway(:with_description, {
          description: "Central hub transit gateway for production",
          tags: { Name: "described-tgw" }
        })
      end

      result = synthesizer.synthesis
      tgw_config = result["resource"]["aws_ec2_transit_gateway"]["with_description"]

      expect(tgw_config["description"]).to eq("Central hub transit gateway for production")
    end

    it "supports DNS support" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway(:dns_enabled, {
          dns_support: "enable",
          tags: { Name: "dns-enabled-tgw" }
        })
      end

      result = synthesizer.synthesis
      tgw_config = result["resource"]["aws_ec2_transit_gateway"]["dns_enabled"]

      expect(tgw_config["dns_support"]).to eq("enable")
    end

    it "supports multicast" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway(:multicast_enabled, {
          multicast_support: "enable",
          tags: { Name: "multicast-tgw" }
        })
      end

      result = synthesizer.synthesis
      tgw_config = result["resource"]["aws_ec2_transit_gateway"]["multicast_enabled"]

      expect(tgw_config["multicast_support"]).to eq("enable")
    end

    it "supports VPN ECMP" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway(:vpn_ecmp, {
          vpn_ecmp_support: "enable",
          tags: { Name: "vpn-ecmp-tgw" }
        })
      end

      result = synthesizer.synthesis
      tgw_config = result["resource"]["aws_ec2_transit_gateway"]["vpn_ecmp"]

      expect(tgw_config["vpn_ecmp_support"]).to eq("enable")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway(:test, {
          description: "Test transit gateway"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_ec2_transit_gateway"]).to be_a(Hash)
      expect(result["resource"]["aws_ec2_transit_gateway"]["test"]).to be_a(Hash)
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ec2_transit_gateway(:test_ref, {
          description: "Test transit gateway",
          tags: { Name: "test-tgw" }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_ec2_transit_gateway.test_ref.id}")
      expect(ref.outputs[:arn]).to eq("${aws_ec2_transit_gateway.test_ref.arn}")
    end
  end
end
