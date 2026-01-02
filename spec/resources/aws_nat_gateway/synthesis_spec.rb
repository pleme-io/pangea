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
require 'pangea/resources/aws_nat_gateway/resource'

RSpec.describe "aws_nat_gateway synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for public NAT gateway" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_nat_gateway(:test, {
          subnet_id: "subnet-12345678",
          allocation_id: "eipalloc-12345678"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_nat_gateway")
      expect(result["resource"]["aws_nat_gateway"]).to have_key("test")

      nat_config = result["resource"]["aws_nat_gateway"]["test"]
      expect(nat_config["subnet_id"]).to eq("subnet-12345678")
      expect(nat_config["allocation_id"]).to eq("eipalloc-12345678")
    end

    it "generates valid terraform JSON for private NAT gateway" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_nat_gateway(:private, {
          subnet_id: "subnet-12345678",
          connectivity_type: "private"
        })
      end

      result = synthesizer.synthesis
      nat_config = result["resource"]["aws_nat_gateway"]["private"]

      expect(nat_config["subnet_id"]).to eq("subnet-12345678")
      expect(nat_config["connectivity_type"]).to eq("private")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_nat_gateway(:test, {
          subnet_id: "subnet-12345678",
          allocation_id: "eipalloc-12345678",
          tags: { Name: "test-nat-gateway", Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      nat_config = result["resource"]["aws_nat_gateway"]["test"]

      expect(nat_config).to have_key("tags")
    end
  end

  describe "resource references" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_nat_gateway(:test, {
          subnet_id: "subnet-12345678",
          allocation_id: "eipalloc-12345678"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_nat_gateway.test.id}")
      expect(ref.allocation_id).to eq("${aws_nat_gateway.test.allocation_id}")
      expect(ref.subnet_id).to eq("${aws_nat_gateway.test.subnet_id}")
      expect(ref.private_ip).to eq("${aws_nat_gateway.test.private_ip}")
      expect(ref.public_ip).to eq("${aws_nat_gateway.test.public_ip}")
    end

    it "supports computed properties for public NAT gateway" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_nat_gateway(:test, {
          subnet_id: "subnet-12345678",
          allocation_id: "eipalloc-12345678"
        })
      end

      expect(ref.public?).to eq(true)
      expect(ref.private?).to eq(false)
    end

    it "supports computed properties for private NAT gateway" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_nat_gateway(:private, {
          subnet_id: "subnet-12345678",
          connectivity_type: "private"
        })
      end

      expect(ref.public?).to eq(false)
      expect(ref.private?).to eq(true)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_nat_gateway(:test, {
          subnet_id: "subnet-12345678",
          allocation_id: "eipalloc-12345678"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_nat_gateway"]).to be_a(Hash)
      expect(result["resource"]["aws_nat_gateway"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      nat_config = result["resource"]["aws_nat_gateway"]["test"]
      expect(nat_config).to have_key("subnet_id")
    end
  end
end
