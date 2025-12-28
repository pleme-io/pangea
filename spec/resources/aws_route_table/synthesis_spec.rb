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
require 'pangea/resources/aws_route_table/resource'

RSpec.describe "aws_route_table synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route_table(:test, {
          vpc_id: "vpc-12345678"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_route_table")
      expect(result["resource"]["aws_route_table"]).to have_key("test")

      rt_config = result["resource"]["aws_route_table"]["test"]
      expect(rt_config["vpc_id"]).to eq("vpc-12345678")
    end

    it "generates route table with internet gateway route" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route_table(:public, {
          vpc_id: "vpc-12345678",
          routes: [{
            cidr_block: "0.0.0.0/0",
            gateway_id: "igw-12345678"
          }]
        })
      end

      result = synthesizer.synthesis
      rt_config = result["resource"]["aws_route_table"]["public"]

      expect(rt_config["vpc_id"]).to eq("vpc-12345678")
    end

    it "generates route table with NAT gateway route" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route_table(:private, {
          vpc_id: "vpc-12345678",
          routes: [{
            cidr_block: "0.0.0.0/0",
            nat_gateway_id: "nat-12345678"
          }]
        })
      end

      result = synthesizer.synthesis
      rt_config = result["resource"]["aws_route_table"]["private"]

      expect(rt_config["vpc_id"]).to eq("vpc-12345678")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route_table(:test, {
          vpc_id: "vpc-12345678",
          tags: { Name: "test-route-table", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      rt_config = result["resource"]["aws_route_table"]["test"]

      expect(rt_config).to have_key("tags")
    end
  end

  describe "resource references" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route_table(:test, {
          vpc_id: "vpc-12345678"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_route_table.test.id}")
      expect(ref.arn).to eq("${aws_route_table.test.arn}")
      expect(ref.owner_id).to eq("${aws_route_table.test.owner_id}")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route_table(:test, {
          vpc_id: "vpc-12345678"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_route_table"]).to be_a(Hash)
      expect(result["resource"]["aws_route_table"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      rt_config = result["resource"]["aws_route_table"]["test"]
      expect(rt_config).to have_key("vpc_id")
    end
  end
end
