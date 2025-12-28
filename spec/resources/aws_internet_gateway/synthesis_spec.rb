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
require 'pangea/resources/aws_internet_gateway/resource'

RSpec.describe "aws_internet_gateway synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON without VPC attachment" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_internet_gateway(:test, {
          tags: { Name: "test-igw" }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_internet_gateway")
      expect(result["resource"]["aws_internet_gateway"]).to have_key("test")
    end

    it "generates valid terraform JSON with VPC attachment" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_internet_gateway(:test, {
          vpc_id: "vpc-12345678",
          tags: { Name: "test-igw" }
        })
      end

      result = synthesizer.synthesis
      igw_config = result["resource"]["aws_internet_gateway"]["test"]

      expect(igw_config["vpc_id"]).to eq("vpc-12345678")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_internet_gateway(:test, {
          vpc_id: "vpc-12345678",
          tags: { Name: "test-igw", Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      igw_config = result["resource"]["aws_internet_gateway"]["test"]

      expect(igw_config).to have_key("tags")
      expect(igw_config["tags"]["Name"]).to eq("test-igw")
      expect(igw_config["tags"]["Environment"]).to eq("production")
    end
  end

  describe "resource references" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_internet_gateway(:test, {
          vpc_id: "vpc-12345678",
          tags: { Name: "test-igw" }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_internet_gateway.test.id}")
      expect(ref.arn).to eq("${aws_internet_gateway.test.arn}")
      expect(ref.owner_id).to eq("${aws_internet_gateway.test.owner_id}")
      expect(ref.vpc_id).to eq("${aws_internet_gateway.test.vpc_id}")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_internet_gateway(:test, {
          vpc_id: "vpc-12345678"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_internet_gateway"]).to be_a(Hash)
      expect(result["resource"]["aws_internet_gateway"]["test"]).to be_a(Hash)
    end
  end
end
