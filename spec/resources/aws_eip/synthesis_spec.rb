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
require 'pangea/resources/aws_eip/resource'

RSpec.describe "aws_eip synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for VPC EIP" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eip(:test, {
          domain: "vpc"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_eip")
      expect(result["resource"]["aws_eip"]).to have_key("test")

      eip_config = result["resource"]["aws_eip"]["test"]
      expect(eip_config["domain"]).to eq("vpc")
    end

    it "generates valid terraform JSON with instance association" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eip(:instance_eip, {
          domain: "vpc",
          instance: "i-12345678"
        })
      end

      result = synthesizer.synthesis
      eip_config = result["resource"]["aws_eip"]["instance_eip"]

      expect(eip_config["domain"]).to eq("vpc")
      expect(eip_config["instance"]).to eq("i-12345678")
    end

    it "generates valid terraform JSON with network interface association" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eip(:eni_eip, {
          domain: "vpc",
          network_interface: "eni-12345678"
        })
      end

      result = synthesizer.synthesis
      eip_config = result["resource"]["aws_eip"]["eni_eip"]

      expect(eip_config["domain"]).to eq("vpc")
      expect(eip_config["network_interface"]).to eq("eni-12345678")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eip(:test, {
          domain: "vpc",
          tags: { Name: "nat-gateway-eip", Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      eip_config = result["resource"]["aws_eip"]["test"]

      expect(eip_config).to have_key("tags")
    end

    it "supports network border group" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eip(:test, {
          domain: "vpc",
          network_border_group: "us-west-2-lax-1"
        })
      end

      result = synthesizer.synthesis
      eip_config = result["resource"]["aws_eip"]["test"]

      expect(eip_config["network_border_group"]).to eq("us-west-2-lax-1")
    end
  end

  describe "resource references" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_eip(:test, {
          domain: "vpc"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_eip.test.id}")
      expect(ref.allocation_id).to eq("${aws_eip.test.allocation_id}")
      expect(ref.public_ip).to eq("${aws_eip.test.public_ip}")
      expect(ref.private_ip).to eq("${aws_eip.test.private_ip}")
      expect(ref.public_dns).to eq("${aws_eip.test.public_dns}")
      expect(ref.private_dns).to eq("${aws_eip.test.private_dns}")
    end

    it "supports computed properties for VPC EIP" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_eip(:test, {
          domain: "vpc"
        })
      end

      expect(ref.vpc?).to eq(true)
    end

    it "supports computed properties for associated EIP" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_eip(:test, {
          domain: "vpc",
          instance: "i-12345678"
        })
      end

      expect(ref.associated?).to eq(true)
      expect(ref.association_type).to eq(:instance)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_eip(:test, {
          domain: "vpc"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_eip"]).to be_a(Hash)
      expect(result["resource"]["aws_eip"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      eip_config = result["resource"]["aws_eip"]["test"]
      expect(eip_config).to have_key("domain")
    end
  end
end
