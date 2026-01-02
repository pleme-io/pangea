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
require 'pangea/resources/aws_subnet/resource'

RSpec.describe "aws_subnet synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_subnet(:test, {
          vpc_id: "vpc-12345678",
          cidr_block: "10.0.1.0/24",
          availability_zone: "us-east-1a"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_subnet")
      expect(result["resource"]["aws_subnet"]).to have_key("test")

      subnet_config = result["resource"]["aws_subnet"]["test"]
      expect(subnet_config["vpc_id"]).to eq("vpc-12345678")
      expect(subnet_config["cidr_block"]).to eq("10.0.1.0/24")
      expect(subnet_config["availability_zone"]).to eq("us-east-1a")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_subnet(:test, {
          vpc_id: "vpc-12345678",
          cidr_block: "10.0.1.0/24",
          availability_zone: "us-east-1a",
          tags: { Name: "test-subnet", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      subnet_config = result["resource"]["aws_subnet"]["test"]

      expect(subnet_config).to have_key("tags")
      expect(subnet_config["tags"]["Name"]).to eq("test-subnet")
      expect(subnet_config["tags"]["Environment"]).to eq("test")
    end

    it "supports public IP mapping on launch" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_subnet(:public, {
          vpc_id: "vpc-12345678",
          cidr_block: "10.0.1.0/24",
          availability_zone: "us-east-1a",
          map_public_ip_on_launch: true
        })
      end

      result = synthesizer.synthesis
      subnet_config = result["resource"]["aws_subnet"]["public"]

      expect(subnet_config["map_public_ip_on_launch"]).to eq(true)
    end
  end

  describe "resource references" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_subnet(:test, {
          vpc_id: "vpc-12345678",
          cidr_block: "10.0.1.0/24",
          availability_zone: "us-east-1a"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_subnet.test.id}")
      expect(ref.arn).to eq("${aws_subnet.test.arn}")
      expect(ref.vpc_id).to eq("${aws_subnet.test.vpc_id}")
      expect(ref.cidr_block).to eq("${aws_subnet.test.cidr_block}")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_subnet(:test, {
          vpc_id: "vpc-12345678",
          cidr_block: "10.0.1.0/24",
          availability_zone: "us-east-1a"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_subnet"]).to be_a(Hash)
      expect(result["resource"]["aws_subnet"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      subnet_config = result["resource"]["aws_subnet"]["test"]
      expect(subnet_config).to have_key("vpc_id")
      expect(subnet_config).to have_key("cidr_block")
      expect(subnet_config).to have_key("availability_zone")
    end
  end
end
