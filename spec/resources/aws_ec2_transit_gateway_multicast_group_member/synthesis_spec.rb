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
require 'pangea/resources/aws_ec2_transit_gateway_multicast_group_member/resource'

RSpec.describe "aws_ec2_transit_gateway_multicast_group_member synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway_multicast_group_member(:test, {
          tags: { Name: "test-multicast-member" }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_ec2_transit_gateway_multicast_group_member")
      expect(result["resource"]["aws_ec2_transit_gateway_multicast_group_member"]).to have_key("test")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway_multicast_group_member(:tagged, {
          tags: { Name: "tagged-member", Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      member_config = result["resource"]["aws_ec2_transit_gateway_multicast_group_member"]["tagged"]

      expect(member_config).to have_key("tags")
      expect(member_config["tags"]["Name"]).to eq("tagged-member")
      expect(member_config["tags"]["Environment"]).to eq("production")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ec2_transit_gateway_multicast_group_member(:test, {
          tags: { Name: "test-member" }
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_ec2_transit_gateway_multicast_group_member"]).to be_a(Hash)
      expect(result["resource"]["aws_ec2_transit_gateway_multicast_group_member"]["test"]).to be_a(Hash)
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ec2_transit_gateway_multicast_group_member(:test_ref, {
          tags: { Name: "test-member" }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_ec2_transit_gateway_multicast_group_member.test_ref.id}")
    end
  end
end
