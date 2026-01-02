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
require 'pangea/resources/aws_ec2_transit_gateway_route/resource'

RSpec.describe "aws_ec2_transit_gateway_route synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for forward route" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway_route(:test, {
          destination_cidr_block: "10.0.0.0/16",
          transit_gateway_route_table_id: "tgw-rtb-12345678",
          transit_gateway_attachment_id: "tgw-attach-12345678"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_ec2_transit_gateway_route")
      expect(result["resource"]["aws_ec2_transit_gateway_route"]).to have_key("test")

      route_config = result["resource"]["aws_ec2_transit_gateway_route"]["test"]
      expect(route_config["destination_cidr_block"]).to eq("10.0.0.0/16")
      expect(route_config["transit_gateway_route_table_id"]).to eq("tgw-rtb-12345678")
      expect(route_config["transit_gateway_attachment_id"]).to eq("tgw-attach-12345678")
    end

    it "generates valid terraform JSON for blackhole route" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway_route(:blackhole, {
          destination_cidr_block: "192.168.0.0/16",
          transit_gateway_route_table_id: "tgw-rtb-12345678",
          blackhole: true
        })
      end

      result = synthesizer.synthesis
      route_config = result["resource"]["aws_ec2_transit_gateway_route"]["blackhole"]

      expect(route_config["destination_cidr_block"]).to eq("192.168.0.0/16")
      expect(route_config["blackhole"]).to eq(true)
    end

    it "generates default route (0.0.0.0/0)" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway_route(:default, {
          destination_cidr_block: "0.0.0.0/0",
          transit_gateway_route_table_id: "tgw-rtb-12345678",
          transit_gateway_attachment_id: "tgw-attach-12345678"
        })
      end

      result = synthesizer.synthesis
      route_config = result["resource"]["aws_ec2_transit_gateway_route"]["default"]

      expect(route_config["destination_cidr_block"]).to eq("0.0.0.0/0")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway_route(:test, {
          destination_cidr_block: "10.0.0.0/16",
          transit_gateway_route_table_id: "tgw-rtb-12345678",
          transit_gateway_attachment_id: "tgw-attach-12345678"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_ec2_transit_gateway_route"]).to be_a(Hash)
      expect(result["resource"]["aws_ec2_transit_gateway_route"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      route_config = result["resource"]["aws_ec2_transit_gateway_route"]["test"]
      expect(route_config).to have_key("destination_cidr_block")
      expect(route_config).to have_key("transit_gateway_route_table_id")
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ec2_transit_gateway_route(:test_ref, {
          destination_cidr_block: "10.0.0.0/16",
          transit_gateway_route_table_id: "tgw-rtb-12345678",
          transit_gateway_attachment_id: "tgw-attach-12345678"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:route_table_id]).to eq("${aws_ec2_transit_gateway_route.test_ref.transit_gateway_route_table_id}")
      expect(ref.outputs[:destination_cidr_block]).to eq("${aws_ec2_transit_gateway_route.test_ref.destination_cidr_block}")
    end
  end
end
