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

# Load just the aws_vpc resource and types for testing
require 'pangea/resources/aws_vpc/resource'
require 'pangea/resources/aws_vpc/types'

RSpec.describe "aws_vpc resource function" do
  # Create a test class that includes the AWS module and mocks terraform-synthesizer
  let(:test_class) do
    Class.new do
      include Pangea::Resources::AWS
      
      # Mock the terraform-synthesizer resource method
      def resource(type, name)
        @resources ||= {}
        resource_data = { type: type, name: name, attributes: {} }
        
        yield if block_given?
        
        @resources["#{type}.#{name}"] = resource_data
        resource_data
      end
      
      # Method missing to capture terraform attributes
      def method_missing(method_name, *args, &block)
        # Don't capture certain methods that might interfere
        return super if [:expect, :be_a, :eq].include?(method_name)
        # For terraform-synthesizer attribute calls, just return the value
        args.first if args.any?
      end
      
      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end
  end
  
  let(:test_instance) { test_class.new }
  
  describe "VPC attributes validation" do
    it "validates CIDR block format using dry-struct" do
      expect {
        Pangea::Resources::AWS::Types::VpcAttributes.new({ cidr_block: "invalid-cidr" })
      }.to raise_error(Dry::Struct::Error, /too large/)
    end
    
    it "rejects CIDR blocks that are too large" do
      expect {
        Pangea::Resources::AWS::Types::VpcAttributes.new({ cidr_block: "10.0.0.0/8" })
      }.to raise_error(Dry::Struct::Error, /too large/)
    end
    
    it "rejects CIDR blocks that are too small" do
      expect {
        Pangea::Resources::AWS::Types::VpcAttributes.new({ cidr_block: "10.0.0.0/29" })
      }.to raise_error(Dry::Struct::Error, /too small/)
    end
    
    it "applies default DNS settings" do
      attrs = Pangea::Resources::AWS::Types::VpcAttributes.new({ cidr_block: "10.0.0.0/16" })
      
      expect(attrs.enable_dns_hostnames).to eq(true)
      expect(attrs.enable_dns_support).to eq(true)
    end
    
    it "accepts custom DNS settings" do
      attrs = Pangea::Resources::AWS::Types::VpcAttributes.new({
        cidr_block: "10.0.0.0/16",
        enable_dns_hostnames: false,
        enable_dns_support: false
      })
      
      expect(attrs.enable_dns_hostnames).to eq(false)
      expect(attrs.enable_dns_support).to eq(false)
    end
    
    it "handles tags correctly" do
      attrs = Pangea::Resources::AWS::Types::VpcAttributes.new({
        cidr_block: "10.0.0.0/16",
        tags: { Name: "test-vpc", Environment: "testing" }
      })
      
      expect(attrs.tags).to eq({
        Name: "test-vpc",
        Environment: "testing"
      })
    end
    
    it "supports dedicated tenancy" do
      attrs = Pangea::Resources::AWS::Types::VpcAttributes.new({
        cidr_block: "10.0.0.0/16",
        instance_tenancy: "dedicated"
      })
      
      expect(attrs.instance_tenancy).to eq("dedicated")
    end
  end
  
  describe "VPC computed properties" do  
    it "computes RFC1918 private network correctly" do
      attrs = Pangea::Resources::AWS::Types::VpcAttributes.new({ cidr_block: "10.0.0.0/16" })
      
      expect(attrs.is_rfc1918_private?).to eq(true)
    end
    
    it "estimates subnet capacity correctly" do
      attrs = Pangea::Resources::AWS::Types::VpcAttributes.new({ cidr_block: "10.0.0.0/16" })
      
      expect(attrs.subnet_count_estimate).to eq(256)
    end
  end
  
  describe "aws_vpc function behavior" do
    it "creates a resource reference with valid CIDR" do
      ref = test_instance.aws_vpc(:test, { cidr_block: "10.0.0.0/16" })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_vpc')
      expect(ref.name).to eq(:test)
    end
    
    it "validates CIDR block format in function call" do
      expect {
        test_instance.aws_vpc(:test, { cidr_block: "invalid-cidr" })
      }.to raise_error(Dry::Struct::Error, /too large/)
    end
    
    it "rejects large CIDR blocks in function call" do
      expect {
        test_instance.aws_vpc(:test, { cidr_block: "10.0.0.0/8" })
      }.to raise_error(Dry::Struct::Error, /too large/)
    end
    
    it "rejects small CIDR blocks in function call" do
      expect {
        test_instance.aws_vpc(:test, { cidr_block: "10.0.0.0/29" })
      }.to raise_error(Dry::Struct::Error, /too small/)
    end
    
    it "applies default DNS settings in function call" do
      ref = test_instance.aws_vpc(:test, { cidr_block: "10.0.0.0/16" })
      
      expect(ref.resource_attributes[:enable_dns_hostnames]).to eq(true)
      expect(ref.resource_attributes[:enable_dns_support]).to eq(true)
    end
    
    it "accepts custom DNS settings in function call" do
      ref = test_instance.aws_vpc(:test, {
        cidr_block: "10.0.0.0/16",
        enable_dns_hostnames: false,
        enable_dns_support: false
      })
      
      expect(ref.resource_attributes[:enable_dns_hostnames]).to eq(false)
      expect(ref.resource_attributes[:enable_dns_support]).to eq(false)
    end
    
    it "handles tags correctly in function call" do
      ref = test_instance.aws_vpc(:test, {
        cidr_block: "10.0.0.0/16",
        tags: { Name: "test-vpc", Environment: "testing" }
      })
      
      expect(ref.resource_attributes[:tags]).to eq({
        Name: "test-vpc",
        Environment: "testing"
      })
    end
    
    it "supports dedicated tenancy in function call" do
      ref = test_instance.aws_vpc(:test, {
        cidr_block: "10.0.0.0/16",
        instance_tenancy: "dedicated"
      })
      
      expect(ref.resource_attributes[:instance_tenancy]).to eq("dedicated")
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_vpc(:test, { cidr_block: "10.0.0.0/16" })
      
      expected_outputs = [:id, :arn, :cidr_block, :default_security_group_id, 
                         :default_route_table_id, :default_network_acl_id]
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_vpc.test.#{output}}")
      end
    end
  end
end