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

RSpec.describe "aws_vpc integration" do
  include Pangea::Resources::AWS
  
  let(:synthesizer) { TerraformSynthesizer.new }
  
  describe "resource references" do
    it "provides terraform output references" do
      ref = aws_vpc(:test, { cidr_block: "10.0.0.0/16" })
      
      # Test reference format
      expect(ref.id).to match(/\$\{aws_vpc\.test\.id\}/)
      expect(ref.arn).to match(/\$\{aws_vpc\.test\.arn\}/)
      expect(ref.cidr_block).to match(/\$\{aws_vpc\.test\.cidr_block\}/)
    end

    it "works with terraform synthesis" do
      vpc_ref = nil
      
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        vpc_ref = aws_vpc(:main_vpc, { 
          cidr_block: "10.0.0.0/16",
          tags: { Name: "main" }
        })
        
        # Use reference in another resource (simulated)
        output(:vpc_id) do
          value vpc_ref.id
          description "Main VPC ID"
        end
      end
      
      result = synthesizer.synthesis
      
      # Check that VPC resource exists
      expect(result["resource"]["aws_vpc"]["main_vpc"]).to be_present
      
      # Check that output uses reference
      expect(result["output"]["vpc_id"]["value"]).to eq("${aws_vpc.main_vpc.id}")
    end
  end

  describe "computed properties" do
    it "provides computed attributes for VPC types" do
      ref = aws_vpc(:test, { cidr_block: "10.0.0.0/16" })
      
      # Access computed properties from the type attributes
      vpc_attrs = ref.resource_attributes
      expect(vpc_attrs[:cidr_block]).to eq("10.0.0.0/16")
      
      # Check that the VPC attributes object has computed methods
      if vpc_attrs.respond_to?(:is_rfc1918_private?)
        expect(vpc_attrs.is_rfc1918_private?).to eq(true)
      end
      
      if vpc_attrs.respond_to?(:subnet_count_estimate)
        expect(vpc_attrs.subnet_count_estimate).to be > 0
      end
    end
  end

  describe "multiple resource creation" do
    it "creates multiple VPCs in synthesis" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        
        # Create multiple VPCs
        aws_vpc(:vpc1, { cidr_block: "10.0.0.0/16" })
        aws_vpc(:vpc2, { 
          cidr_block: "172.16.0.0/16",
          instance_tenancy: "dedicated"
        })
        aws_vpc(:vpc3, { 
          cidr_block: "192.168.0.0/16",
          tags: { Environment: "test" }
        })
      end
      
      result = synthesizer.synthesis
      
      expect(result["resource"]["aws_vpc"]).to have_key("vpc1")
      expect(result["resource"]["aws_vpc"]).to have_key("vpc2")
      expect(result["resource"]["aws_vpc"]).to have_key("vpc3")
      
      # Verify different configurations
      expect(result["resource"]["aws_vpc"]["vpc1"]["cidr_block"]).to eq("10.0.0.0/16")
      expect(result["resource"]["aws_vpc"]["vpc2"]["instance_tenancy"]).to eq("dedicated")
      expect(result["resource"]["aws_vpc"]["vpc3"]["tags"]["Environment"]).to eq("test")
    end
  end
end