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

# Load aws_nat_gateway resource and types for testing
require 'pangea/resources/aws_nat_gateway/resource'
require 'pangea/resources/aws_nat_gateway/types'

RSpec.describe "aws_nat_gateway resource function" do
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
  let(:subnet_id) { "${aws_subnet.public.id}" }
  let(:allocation_id) { "${aws_eip.nat.id}" }
  
  describe "NatGatewayAttributes validation" do
    it "validates required subnet_id attribute" do
      expect {
        Pangea::Resources::AWS::Types::NatGatewayAttributes.new({
          tags: { Name: "test-nat" }
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "accepts minimal NAT gateway with subnet_id only (public default)" do
      attrs = Pangea::Resources::AWS::Types::NatGatewayAttributes.new({
        subnet_id: subnet_id
      })
      
      expect(attrs.subnet_id).to eq(subnet_id)
      expect(attrs.allocation_id).to be_nil
      expect(attrs.connectivity_type).to eq("public")
      expect(attrs.tags).to eq({})
    end
    
    it "accepts public NAT gateway with allocation_id" do
      attrs = Pangea::Resources::AWS::Types::NatGatewayAttributes.new({
        subnet_id: subnet_id,
        allocation_id: allocation_id,
        connectivity_type: "public"
      })
      
      expect(attrs.subnet_id).to eq(subnet_id)
      expect(attrs.allocation_id).to eq(allocation_id)
      expect(attrs.connectivity_type).to eq("public")
    end
    
    it "accepts private NAT gateway without allocation_id" do
      attrs = Pangea::Resources::AWS::Types::NatGatewayAttributes.new({
        subnet_id: subnet_id,
        connectivity_type: "private"
      })
      
      expect(attrs.subnet_id).to eq(subnet_id)
      expect(attrs.allocation_id).to be_nil
      expect(attrs.connectivity_type).to eq("private")
    end
    
    it "accepts NAT gateway with tags" do
      attrs = Pangea::Resources::AWS::Types::NatGatewayAttributes.new({
        subnet_id: subnet_id,
        tags: { 
          Name: "main-nat-gateway",
          Environment: "production",
          Type: "nat"
        }
      })
      
      expect(attrs.tags).to eq({
        Name: "main-nat-gateway",
        Environment: "production",
        Type: "nat"
      })
    end
    
    it "validates that allocation_id cannot be used with private NAT gateway" do
      expect {
        Pangea::Resources::AWS::Types::NatGatewayAttributes.new({
          subnet_id: subnet_id,
          allocation_id: allocation_id,
          connectivity_type: "private"
        })
      }.to raise_error(Dry::Struct::Error, /allocation_id can only be used with public NAT gateways/)
    end
    
    it "validates connectivity_type enum values" do
      expect {
        Pangea::Resources::AWS::Types::NatGatewayAttributes.new({
          subnet_id: subnet_id,
          connectivity_type: "invalid"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    describe "computed properties" do
      it "correctly identifies public NAT gateway" do
        attrs = Pangea::Resources::AWS::Types::NatGatewayAttributes.new({
          subnet_id: subnet_id,
          connectivity_type: "public"
        })
        
        expect(attrs.public?).to eq(true)
        expect(attrs.private?).to eq(false)
      end
      
      it "correctly identifies private NAT gateway" do
        attrs = Pangea::Resources::AWS::Types::NatGatewayAttributes.new({
          subnet_id: subnet_id,
          connectivity_type: "private"
        })
        
        expect(attrs.public?).to eq(false)
        expect(attrs.private?).to eq(true)
      end
      
      it "detects when elastic IP is required (public without allocation_id)" do
        attrs = Pangea::Resources::AWS::Types::NatGatewayAttributes.new({
          subnet_id: subnet_id,
          connectivity_type: "public"
        })
        
        expect(attrs.requires_elastic_ip?).to eq(true)
      end
      
      it "detects when elastic IP is provided (public with allocation_id)" do
        attrs = Pangea::Resources::AWS::Types::NatGatewayAttributes.new({
          subnet_id: subnet_id,
          allocation_id: allocation_id,
          connectivity_type: "public"
        })
        
        expect(attrs.requires_elastic_ip?).to eq(false)
      end
      
      it "detects private NAT gateway doesn't require elastic IP" do
        attrs = Pangea::Resources::AWS::Types::NatGatewayAttributes.new({
          subnet_id: subnet_id,
          connectivity_type: "private"
        })
        
        expect(attrs.requires_elastic_ip?).to eq(false)
      end
    end
    
    it "converts to hash correctly, excluding nil values" do
      attrs = Pangea::Resources::AWS::Types::NatGatewayAttributes.new({
        subnet_id: subnet_id,
        allocation_id: allocation_id
      })
      
      hash = attrs.to_h
      expect(hash).to eq({
        subnet_id: subnet_id,
        allocation_id: allocation_id,
        connectivity_type: "public",
        tags: {}
      })
      expect(hash).to have_key(:connectivity_type)
      expect(hash).to have_key(:tags)
    end
    
    it "compacts hash when allocation_id is nil" do
      attrs = Pangea::Resources::AWS::Types::NatGatewayAttributes.new({
        subnet_id: subnet_id
      })
      
      hash = attrs.to_h
      expect(hash[:subnet_id]).to eq(subnet_id)
      expect(hash[:connectivity_type]).to eq("public")
      expect(hash[:tags]).to eq({})
      # allocation_id should be compacted out when nil
    end
  end
  
  describe "aws_nat_gateway function behavior" do
    it "creates a resource reference with minimal attributes" do
      ref = test_instance.aws_nat_gateway(:test, {
        subnet_id: subnet_id
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_nat_gateway')
      expect(ref.name).to eq(:test)
    end
    
    it "creates a resource reference with allocation_id" do
      ref = test_instance.aws_nat_gateway(:public_nat, {
        subnet_id: subnet_id,
        allocation_id: allocation_id
      })
      
      expect(ref.resource_attributes[:subnet_id]).to eq(subnet_id)
      expect(ref.resource_attributes[:allocation_id]).to eq(allocation_id)
      expect(ref.resource_attributes[:connectivity_type]).to eq("public")
    end
    
    it "creates a resource reference for private NAT gateway" do
      ref = test_instance.aws_nat_gateway(:private_nat, {
        subnet_id: subnet_id,
        connectivity_type: "private"
      })
      
      expect(ref.resource_attributes[:subnet_id]).to eq(subnet_id)
      expect(ref.resource_attributes[:connectivity_type]).to eq("private")
      expect(ref.resource_attributes[:allocation_id]).to be_nil
    end
    
    it "handles tags correctly" do
      ref = test_instance.aws_nat_gateway(:tagged_nat, {
        subnet_id: subnet_id,
        tags: { 
          Name: "tagged-nat-gateway", 
          Environment: "test",
          Purpose: "internet-access"
        }
      })
      
      expect(ref.resource_attributes[:tags]).to eq({
        Name: "tagged-nat-gateway",
        Environment: "test", 
        Purpose: "internet-access"
      })
    end
    
    it "validates attributes in function call" do
      expect {
        test_instance.aws_nat_gateway(:invalid, {
          subnet_id: subnet_id,
          allocation_id: allocation_id,
          connectivity_type: "private"
        })
      }.to raise_error(Dry::Struct::Error, /allocation_id can only be used with public NAT gateways/)
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_nat_gateway(:test, { subnet_id: subnet_id })
      
      expected_outputs = [:id, :allocation_id, :subnet_id, :network_interface_id, :private_ip, :public_ip]
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_nat_gateway.test.")
      end
    end
    
    it "provides computed properties via method delegation" do
      ref = test_instance.aws_nat_gateway(:test, { 
        subnet_id: subnet_id,
        connectivity_type: "public"
      })
      
      expect(ref.public?).to eq(true)
      expect(ref.private?).to eq(false)
      expect(ref.requires_elastic_ip?).to eq(true)
    end
    
    it "provides computed properties for private NAT gateway" do
      ref = test_instance.aws_nat_gateway(:private, { 
        subnet_id: subnet_id,
        connectivity_type: "private"
      })
      
      expect(ref.public?).to eq(false)
      expect(ref.private?).to eq(true)
      expect(ref.requires_elastic_ip?).to eq(false)
    end
  end
  
  describe "common NAT gateway patterns" do
    it "creates a public NAT gateway with Elastic IP" do
      ref = test_instance.aws_nat_gateway(:public, {
        subnet_id: subnet_id,
        allocation_id: allocation_id,
        tags: {
          Name: "public-nat-gateway",
          Type: "public"
        }
      })
      
      expect(ref.resource_attributes[:subnet_id]).to eq(subnet_id)
      expect(ref.resource_attributes[:allocation_id]).to eq(allocation_id)
      expect(ref.resource_attributes[:connectivity_type]).to eq("public")
      expect(ref.resource_attributes[:tags][:Type]).to eq("public")
      expect(ref.public?).to eq(true)
    end
    
    it "creates a public NAT gateway without explicit Elastic IP (AWS managed)" do
      ref = test_instance.aws_nat_gateway(:aws_managed, {
        subnet_id: subnet_id,
        connectivity_type: "public",
        tags: {
          Name: "aws-managed-nat-gateway",
          Type: "public-aws-managed"
        }
      })
      
      expect(ref.resource_attributes[:subnet_id]).to eq(subnet_id)
      expect(ref.resource_attributes[:allocation_id]).to be_nil
      expect(ref.resource_attributes[:connectivity_type]).to eq("public")
      expect(ref.requires_elastic_ip?).to eq(true)
      expect(ref.public?).to eq(true)
    end
    
    it "creates a private NAT gateway for VPC endpoints" do
      ref = test_instance.aws_nat_gateway(:private, {
        subnet_id: subnet_id,
        connectivity_type: "private",
        tags: {
          Name: "private-nat-gateway",
          Type: "private",
          Purpose: "vpc-endpoints"
        }
      })
      
      expect(ref.resource_attributes[:subnet_id]).to eq(subnet_id)
      expect(ref.resource_attributes[:connectivity_type]).to eq("private")
      expect(ref.resource_attributes[:allocation_id]).to be_nil
      expect(ref.resource_attributes[:tags][:Purpose]).to eq("vpc-endpoints")
      expect(ref.private?).to eq(true)
      expect(ref.requires_elastic_ip?).to eq(false)
    end
    
    it "creates multi-AZ NAT gateway setup" do
      azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
      nat_gateways = {}
      
      azs.each do |az|
        nat_gateways[az] = test_instance.aws_nat_gateway(:"nat_#{az.last}", {
          subnet_id: "${aws_subnet.public_#{az.last}.id}",
          allocation_id: "${aws_eip.nat_#{az.last}.id}",
          tags: {
            Name: "nat-gateway-#{az}",
            AvailabilityZone: az,
            Type: "public"
          }
        })
      end
      
      expect(nat_gateways.length).to eq(3)
      nat_gateways.each do |az, nat_ref|
        expect(nat_ref.public?).to eq(true)
        expect(nat_ref.resource_attributes[:tags][:AvailabilityZone]).to eq(az)
      end
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_nat_gateway(:test_nat, { 
        subnet_id: subnet_id,
        allocation_id: allocation_id
      })
      
      expect(ref.outputs[:id]).to eq("${aws_nat_gateway.test_nat.id}")
      expect(ref.outputs[:allocation_id]).to eq("${aws_nat_gateway.test_nat.allocation_id}")
      expect(ref.outputs[:subnet_id]).to eq("${aws_nat_gateway.test_nat.subnet_id}")
      expect(ref.outputs[:network_interface_id]).to eq("${aws_nat_gateway.test_nat.network_interface_id}")
      expect(ref.outputs[:private_ip]).to eq("${aws_nat_gateway.test_nat.private_ip}")
      expect(ref.outputs[:public_ip]).to eq("${aws_nat_gateway.test_nat.public_ip}")
    end
    
    it "can be used in route table routes" do
      nat_gateway_ref = test_instance.aws_nat_gateway(:main, {
        subnet_id: subnet_id,
        allocation_id: allocation_id
      })
      
      # Simulate using NAT gateway reference in route table
      nat_gateway_id = nat_gateway_ref.outputs[:id]
      
      expect(nat_gateway_id).to eq("${aws_nat_gateway.main.id}")
    end
    
    it "supports cross-resource reference patterns" do
      # NAT gateway references EIP and subnet
      ref = test_instance.aws_nat_gateway(:cross_ref, {
        subnet_id: "${aws_subnet.public_a.id}",
        allocation_id: "${aws_eip.nat_a.id}",
        tags: {
          Name: "cross-reference-nat",
          SubnetRef: "${aws_subnet.public_a.cidr_block}",
          EipRef: "${aws_eip.nat_a.public_ip}"
        }
      })
      
      expect(ref.resource_attributes[:subnet_id]).to include("aws_subnet.public_a.id")
      expect(ref.resource_attributes[:allocation_id]).to include("aws_eip.nat_a.id")
      expect(ref.resource_attributes[:tags][:SubnetRef]).to include("aws_subnet.public_a.cidr_block")
    end
  end
  
  describe "error conditions and edge cases" do
    it "handles empty tags gracefully" do
      ref = test_instance.aws_nat_gateway(:empty_tags, {
        subnet_id: subnet_id,
        tags: {}
      })
      
      expect(ref.resource_attributes[:tags]).to eq({})
    end
    
    it "handles string keys in attributes" do
      ref = test_instance.aws_nat_gateway(:string_keys, {
        "subnet_id" => subnet_id,
        "allocation_id" => allocation_id,
        "connectivity_type" => "public"
      })
      
      expect(ref.resource_attributes[:subnet_id]).to eq(subnet_id)
      expect(ref.resource_attributes[:allocation_id]).to eq(allocation_id)
      expect(ref.resource_attributes[:connectivity_type]).to eq("public")
    end
  end
end