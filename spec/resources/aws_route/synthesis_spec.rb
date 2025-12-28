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
require 'pangea/resources/aws_route/resource'

RSpec.describe "aws_route synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with internet gateway" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route(:internet, {
          route_table_id: "rtb-12345678",
          destination_cidr_block: "0.0.0.0/0",
          gateway_id: "igw-12345678"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_route")
      expect(result["resource"]["aws_route"]).to have_key("internet")

      route_config = result["resource"]["aws_route"]["internet"]
      expect(route_config["route_table_id"]).to eq("rtb-12345678")
      expect(route_config["destination_cidr_block"]).to eq("0.0.0.0/0")
      expect(route_config["gateway_id"]).to eq("igw-12345678")
    end

    it "generates valid terraform JSON with NAT gateway" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route(:nat, {
          route_table_id: "rtb-12345678",
          destination_cidr_block: "0.0.0.0/0",
          nat_gateway_id: "nat-12345678"
        })
      end

      result = synthesizer.synthesis
      route_config = result["resource"]["aws_route"]["nat"]

      expect(route_config["route_table_id"]).to eq("rtb-12345678")
      expect(route_config["destination_cidr_block"]).to eq("0.0.0.0/0")
      expect(route_config["nat_gateway_id"]).to eq("nat-12345678")
    end

    it "generates valid terraform JSON with transit gateway" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route(:transit, {
          route_table_id: "rtb-12345678",
          destination_cidr_block: "10.0.0.0/8",
          transit_gateway_id: "tgw-12345678"
        })
      end

      result = synthesizer.synthesis
      route_config = result["resource"]["aws_route"]["transit"]

      expect(route_config["route_table_id"]).to eq("rtb-12345678")
      expect(route_config["destination_cidr_block"]).to eq("10.0.0.0/8")
      expect(route_config["transit_gateway_id"]).to eq("tgw-12345678")
    end

    it "generates valid terraform JSON with VPC peering connection" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route(:peering, {
          route_table_id: "rtb-12345678",
          destination_cidr_block: "172.16.0.0/16",
          vpc_peering_connection_id: "pcx-12345678"
        })
      end

      result = synthesizer.synthesis
      route_config = result["resource"]["aws_route"]["peering"]

      expect(route_config["route_table_id"]).to eq("rtb-12345678")
      expect(route_config["destination_cidr_block"]).to eq("172.16.0.0/16")
      expect(route_config["vpc_peering_connection_id"]).to eq("pcx-12345678")
    end

    it "supports IPv6 destination CIDR" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route(:ipv6, {
          route_table_id: "rtb-12345678",
          destination_ipv6_cidr_block: "::/0",
          gateway_id: "igw-12345678"
        })
      end

      result = synthesizer.synthesis
      route_config = result["resource"]["aws_route"]["ipv6"]

      expect(route_config["destination_ipv6_cidr_block"]).to eq("::/0")
    end
  end

  describe "resource references" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route(:test, {
          route_table_id: "rtb-12345678",
          destination_cidr_block: "0.0.0.0/0",
          gateway_id: "igw-12345678"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_route.test.id}")
      expect(ref.origin).to eq("${aws_route.test.origin}")
      expect(ref.state).to eq("${aws_route.test.state}")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route(:test, {
          route_table_id: "rtb-12345678",
          destination_cidr_block: "0.0.0.0/0",
          gateway_id: "igw-12345678"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_route"]).to be_a(Hash)
      expect(result["resource"]["aws_route"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      route_config = result["resource"]["aws_route"]["test"]
      expect(route_config).to have_key("route_table_id")
      expect(route_config).to have_key("destination_cidr_block")
    end
  end
end
