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

# Load aws_internet_gateway resource and types for testing
require 'pangea/resources/aws_internet_gateway/resource'
require 'pangea/resources/aws_internet_gateway/types'

RSpec.describe "aws_internet_gateway resource function" do
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
  let(:vpc_id) { "${aws_vpc.test.id}" }
  
  describe "InternetGatewayAttributes validation" do
    it "accepts minimal attributes with defaults" do
      attrs = Pangea::Resources::AWS::Types::InternetGatewayAttributes.new({})
      
      expect(attrs.vpc_id).to be_nil
      expect(attrs.tags).to eq({})
    end
    
    it "accepts VPC ID attribute" do
      attrs = Pangea::Resources::AWS::Types::InternetGatewayAttributes.new({
        vpc_id: vpc_id
      })
      
      expect(attrs.vpc_id).to eq(vpc_id)
    end
    
    it "accepts tags attribute" do
      attrs = Pangea::Resources::AWS::Types::InternetGatewayAttributes.new({
        tags: { Name: "main-igw", Environment: "production" }
      })
      
      expect(attrs.tags).to eq({
        Name: "main-igw",
        Environment: "production"
      })
    end
    
    it "accepts both VPC ID and tags" do
      attrs = Pangea::Resources::AWS::Types::InternetGatewayAttributes.new({
        vpc_id: vpc_id,
        tags: { Name: "main-igw" }
      })
      
      expect(attrs.vpc_id).to eq(vpc_id)
      expect(attrs.tags).to eq({ Name: "main-igw" })
    end
    
    describe "computed properties" do
      it "reports attached status correctly when VPC ID is present" do
        attrs = Pangea::Resources::AWS::Types::InternetGatewayAttributes.new({
          vpc_id: vpc_id
        })
        
        expect(attrs.attached?).to eq(true)
      end
      
      it "reports attached status correctly when VPC ID is nil" do
        attrs = Pangea::Resources::AWS::Types::InternetGatewayAttributes.new({})
        
        expect(attrs.attached?).to eq(false)
      end
      
      it "converts to hash correctly" do
        attrs = Pangea::Resources::AWS::Types::InternetGatewayAttributes.new({
          vpc_id: vpc_id,
          tags: { Name: "test-igw" }
        })
        
        hash = attrs.to_h
        expect(hash).to eq({
          vpc_id: vpc_id,
          tags: { Name: "test-igw" }
        })
      end
      
      it "compacts nil values in hash conversion" do
        attrs = Pangea::Resources::AWS::Types::InternetGatewayAttributes.new({
          tags: { Name: "test-igw" }
        })
        
        hash = attrs.to_h
        expect(hash).to eq({
          tags: { Name: "test-igw" }
        })
        expect(hash).not_to have_key(:vpc_id)
      end
    end
  end
  
  describe "aws_internet_gateway function behavior" do
    it "creates a resource reference with minimal attributes" do
      ref = test_instance.aws_internet_gateway(:test, {})
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_internet_gateway')
      expect(ref.name).to eq(:test)
    end
    
    it "creates a resource reference with VPC attachment" do
      ref = test_instance.aws_internet_gateway(:main_igw, {
        vpc_id: vpc_id
      })
      
      expect(ref.resource_attributes[:vpc_id]).to eq(vpc_id)
    end
    
    it "creates a resource reference with tags" do
      ref = test_instance.aws_internet_gateway(:tagged_igw, {
        tags: { Name: "main-igw", Environment: "prod" }
      })
      
      expect(ref.resource_attributes[:tags]).to eq({
        Name: "main-igw",
        Environment: "prod"
      })
    end
    
    it "handles both VPC ID and tags correctly" do
      ref = test_instance.aws_internet_gateway(:complete_igw, {
        vpc_id: vpc_id,
        tags: { Name: "complete-igw", Purpose: "internet-access" }
      })
      
      expect(ref.resource_attributes[:vpc_id]).to eq(vpc_id)
      expect(ref.resource_attributes[:tags]).to eq({
        Name: "complete-igw",
        Purpose: "internet-access"
      })
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_internet_gateway(:test, {})
      
      expected_outputs = [:id, :arn, :owner_id, :vpc_id]
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_internet_gateway.test.#{output}}")
      end
    end
    
    it "stores resource attributes correctly" do
      ref = test_instance.aws_internet_gateway(:test, {
        vpc_id: vpc_id,
        tags: { Name: "test-igw" }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:vpc_id]).to eq(vpc_id)
      expect(attrs[:tags]).to eq({ Name: "test-igw" })
    end
  end
  
  describe "common internet gateway patterns" do
    it "creates a basic internet gateway without VPC attachment" do
      ref = test_instance.aws_internet_gateway(:basic_igw, {
        tags: { Name: "basic-igw", Environment: "development" }
      })
      
      expect(ref.resource_attributes[:vpc_id]).to be_nil
      expect(ref.resource_attributes[:tags][:Name]).to eq("basic-igw")
      expect(ref.resource_attributes[:tags][:Environment]).to eq("development")
    end
    
    it "creates an internet gateway with VPC attachment" do
      ref = test_instance.aws_internet_gateway(:attached_igw, {
        vpc_id: vpc_id,
        tags: { 
          Name: "main-igw", 
          Environment: "production",
          Purpose: "public-internet-access"
        }
      })
      
      expect(ref.resource_attributes[:vpc_id]).to eq(vpc_id)
      expect(ref.resource_attributes[:tags][:Purpose]).to eq("public-internet-access")
    end
    
    it "creates a minimal internet gateway for testing" do
      ref = test_instance.aws_internet_gateway(:minimal_igw, {})
      
      expect(ref.resource_attributes[:vpc_id]).to be_nil
      expect(ref.resource_attributes[:tags]).to eq({})
    end
    
    it "creates an internet gateway for multi-environment setup" do
      environments = ["dev", "staging", "prod"]
      
      environments.each do |env|
        ref = test_instance.aws_internet_gateway(:"#{env}_igw", {
          vpc_id: "${aws_vpc.#{env}.id}",
          tags: {
            Name: "#{env}-igw",
            Environment: env,
            ManagedBy: "pangea"
          }
        })
        
        expect(ref.resource_attributes[:vpc_id]).to eq("${aws_vpc.#{env}.id}")
        expect(ref.resource_attributes[:tags][:Environment]).to eq(env)
        expect(ref.resource_attributes[:tags][:ManagedBy]).to eq("pangea")
      end
    end
    
    it "creates an internet gateway for public subnet routing" do
      ref = test_instance.aws_internet_gateway(:public_igw, {
        vpc_id: vpc_id,
        tags: {
          Name: "public-internet-gateway",
          Type: "public",
          Role: "internet-access"
        }
      })
      
      expect(ref.resource_attributes[:vpc_id]).to eq(vpc_id)
      expect(ref.resource_attributes[:tags][:Type]).to eq("public")
      expect(ref.resource_attributes[:tags][:Role]).to eq("internet-access")
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_internet_gateway(:test_igw, { vpc_id: vpc_id })
      
      expect(ref.outputs[:id]).to eq("${aws_internet_gateway.test_igw.id}")
      expect(ref.outputs[:arn]).to eq("${aws_internet_gateway.test_igw.arn}")
      expect(ref.outputs[:owner_id]).to eq("${aws_internet_gateway.test_igw.owner_id}")
      expect(ref.outputs[:vpc_id]).to eq("${aws_internet_gateway.test_igw.vpc_id}")
    end
    
    it "can be used in route table configurations" do
      igw_ref = test_instance.aws_internet_gateway(:main_igw, { vpc_id: vpc_id })
      
      # Simulate using IGW reference in route table
      gateway_id = igw_ref.outputs[:id]
      
      expect(gateway_id).to eq("${aws_internet_gateway.main_igw.id}")
    end
  end
end