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
require 'pangea/resources/aws_vpc/resource'

RSpec.describe "aws_vpc synthesis" do
  include Pangea::Resources::AWS
  
  let(:synthesizer) { TerraformSynthesizer.new }
  
  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc(:test, {
          cidr_block: "10.0.0.0/16",
          enable_dns_hostnames: true,
          tags: { Name: "test-vpc" }
        })
      end
      
      result = synthesizer.synthesis
      
      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_vpc")
      expect(result["resource"]["aws_vpc"]).to have_key("test")
      
      vpc_config = result["resource"]["aws_vpc"]["test"]
      expect(vpc_config["cidr_block"]).to eq("10.0.0.0/16")
      expect(vpc_config["enable_dns_hostnames"]).to eq(true)
    end
    
    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc(:test, {
          cidr_block: "10.0.0.0/16",
          tags: { Name: "test-vpc", Environment: "test" }
        })
      end
      
      result = synthesizer.synthesis
      vpc_config = result["resource"]["aws_vpc"]["test"]
      
      expect(vpc_config).to have_key("tags")
      expect(vpc_config["tags"]["Name"]).to eq("test-vpc")
      expect(vpc_config["tags"]["Environment"]).to eq("test")
    end

    it "applies default values correctly" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc(:test, { cidr_block: "10.0.0.0/16" })
      end
      
      result = synthesizer.synthesis
      vpc_config = result["resource"]["aws_vpc"]["test"]
      
      expect(vpc_config["cidr_block"]).to eq("10.0.0.0/16")
      expect(vpc_config["enable_dns_hostnames"]).to eq(true)
      expect(vpc_config["enable_dns_support"]).to eq(true)
    end

    it "supports dedicated tenancy" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc(:test, {
          cidr_block: "10.0.0.0/16",
          instance_tenancy: "dedicated"
        })
      end
      
      result = synthesizer.synthesis
      vpc_config = result["resource"]["aws_vpc"]["test"]
      
      expect(vpc_config["instance_tenancy"]).to eq("dedicated")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_vpc(:test, { cidr_block: "10.0.0.0/16" })
      end
      
      result = synthesizer.synthesis
      
      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_vpc"]).to be_a(Hash)
      expect(result["resource"]["aws_vpc"]["test"]).to be_a(Hash)
      
      # Validate required attributes are present
      vpc_config = result["resource"]["aws_vpc"]["test"]
      expect(vpc_config).to have_key("cidr_block")
      expect(vpc_config["cidr_block"]).to be_a(String)
    end
  end
end