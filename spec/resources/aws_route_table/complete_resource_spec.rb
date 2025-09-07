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

# Load aws_route_table resource and types for testing
require 'pangea/resources/aws_route_table/resource'
require 'pangea/resources/aws_route_table/types'

RSpec.describe "aws_route_table resource function" do
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
  let(:igw_id) { "${aws_internet_gateway.test.id}" }
  let(:nat_id) { "${aws_nat_gateway.test.id}" }
  
  describe "RouteAttributes validation" do
    it "validates that route must have a destination" do
      expect {
        Pangea::Resources::AWS::Types::RouteAttributes.new({
          gateway_id: igw_id
        })
      }.to raise_error(Dry::Struct::Error, /Route must have either cidr_block or ipv6_cidr_block/)
    end
    
    it "validates that route must have a target" do
      expect {
        Pangea::Resources::AWS::Types::RouteAttributes.new({
          cidr_block: "0.0.0.0/0"
        })
      }.to raise_error(Dry::Struct::Error, /Route must specify exactly one target/)
    end
    
    it "validates that route can only have one target" do
      expect {
        Pangea::Resources::AWS::Types::RouteAttributes.new({
          cidr_block: "0.0.0.0/0",
          gateway_id: igw_id,
          nat_gateway_id: nat_id
        })
      }.to raise_error(Dry::Struct::Error, /Route can only have one target, but multiple were specified/)
    end
    
    it "accepts valid route with CIDR block and gateway" do
      attrs = Pangea::Resources::AWS::Types::RouteAttributes.new({
        cidr_block: "0.0.0.0/0",
        gateway_id: igw_id
      })
      
      expect(attrs.cidr_block).to eq("0.0.0.0/0")
      expect(attrs.gateway_id).to eq(igw_id)
    end
    
    it "accepts valid route with IPv6 CIDR and egress-only gateway" do
      attrs = Pangea::Resources::AWS::Types::RouteAttributes.new({
        ipv6_cidr_block: "::/0",
        egress_only_gateway_id: "${aws_egress_only_internet_gateway.test.id}"
      })
      
      expect(attrs.ipv6_cidr_block).to eq("::/0")
      expect(attrs.egress_only_gateway_id).to eq("${aws_egress_only_internet_gateway.test.id}")
    end
    
    it "accepts route with NAT gateway target" do
      attrs = Pangea::Resources::AWS::Types::RouteAttributes.new({
        cidr_block: "0.0.0.0/0",
        nat_gateway_id: nat_id
      })
      
      expect(attrs.cidr_block).to eq("0.0.0.0/0")
      expect(attrs.nat_gateway_id).to eq(nat_id)
    end
    
    it "accepts route with VPC peering connection" do
      attrs = Pangea::Resources::AWS::Types::RouteAttributes.new({
        cidr_block: "10.1.0.0/16",
        vpc_peering_connection_id: "${aws_vpc_peering_connection.test.id}"
      })
      
      expect(attrs.cidr_block).to eq("10.1.0.0/16")
      expect(attrs.vpc_peering_connection_id).to eq("${aws_vpc_peering_connection.test.id}")
    end
    
    it "accepts route with transit gateway" do
      attrs = Pangea::Resources::AWS::Types::RouteAttributes.new({
        cidr_block: "192.168.0.0/16",
        transit_gateway_id: "${aws_ec2_transit_gateway.test.id}"
      })
      
      expect(attrs.cidr_block).to eq("192.168.0.0/16")
      expect(attrs.transit_gateway_id).to eq("${aws_ec2_transit_gateway.test.id}")
    end
    
    it "converts to hash correctly, excluding nil values" do
      attrs = Pangea::Resources::AWS::Types::RouteAttributes.new({
        cidr_block: "0.0.0.0/0",
        gateway_id: igw_id
      })
      
      hash = attrs.to_h
      expect(hash).to eq({
        cidr_block: "0.0.0.0/0",
        gateway_id: igw_id
      })
      expect(hash).not_to have_key(:nat_gateway_id)
      expect(hash).not_to have_key(:ipv6_cidr_block)
    end
  end
  
  describe "RouteTableAttributes validation" do
    it "validates required vpc_id attribute" do
      expect {
        Pangea::Resources::AWS::Types::RouteTableAttributes.new({
          routes: []
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "accepts minimal route table with VPC ID" do
      attrs = Pangea::Resources::AWS::Types::RouteTableAttributes.new({
        vpc_id: vpc_id
      })
      
      expect(attrs.vpc_id).to eq(vpc_id)
      expect(attrs.routes).to eq([])
      expect(attrs.tags).to eq({})
    end
    
    it "accepts route table with routes" do
      routes = [
        {
          cidr_block: "0.0.0.0/0",
          gateway_id: igw_id
        }
      ]
      
      attrs = Pangea::Resources::AWS::Types::RouteTableAttributes.new({
        vpc_id: vpc_id,
        routes: routes
      })
      
      expect(attrs.vpc_id).to eq(vpc_id)
      expect(attrs.routes.length).to eq(1)
      expect(attrs.routes.first.cidr_block).to eq("0.0.0.0/0")
      expect(attrs.routes.first.gateway_id).to eq(igw_id)
    end
    
    it "accepts route table with tags" do
      attrs = Pangea::Resources::AWS::Types::RouteTableAttributes.new({
        vpc_id: vpc_id,
        tags: { Name: "public-rt", Environment: "production" }
      })
      
      expect(attrs.tags).to eq({
        Name: "public-rt",
        Environment: "production"
      })
    end
    
    describe "computed properties" do
      it "calculates route count correctly" do
        routes = [
          { cidr_block: "0.0.0.0/0", gateway_id: igw_id },
          { cidr_block: "10.1.0.0/16", vpc_peering_connection_id: "${aws_vpc_peering_connection.test.id}" }
        ]
        
        attrs = Pangea::Resources::AWS::Types::RouteTableAttributes.new({
          vpc_id: vpc_id,
          routes: routes
        })
        
        expect(attrs.route_count).to eq(2)
      end
      
      it "detects internet route correctly" do
        routes = [
          { cidr_block: "0.0.0.0/0", gateway_id: igw_id }
        ]
        
        attrs = Pangea::Resources::AWS::Types::RouteTableAttributes.new({
          vpc_id: vpc_id,
          routes: routes
        })
        
        expect(attrs.has_internet_route?).to eq(true)
      end
      
      it "detects absence of internet route" do
        routes = [
          { cidr_block: "10.1.0.0/16", vpc_peering_connection_id: "${aws_vpc_peering_connection.test.id}" }
        ]
        
        attrs = Pangea::Resources::AWS::Types::RouteTableAttributes.new({
          vpc_id: vpc_id,
          routes: routes
        })
        
        expect(attrs.has_internet_route?).to eq(false)
      end
      
      it "detects NAT route correctly" do
        routes = [
          { cidr_block: "0.0.0.0/0", nat_gateway_id: nat_id }
        ]
        
        attrs = Pangea::Resources::AWS::Types::RouteTableAttributes.new({
          vpc_id: vpc_id,
          routes: routes
        })
        
        expect(attrs.has_nat_route?).to eq(true)
      end
      
      it "detects absence of NAT route" do
        routes = [
          { cidr_block: "0.0.0.0/0", gateway_id: igw_id }
        ]
        
        attrs = Pangea::Resources::AWS::Types::RouteTableAttributes.new({
          vpc_id: vpc_id,
          routes: routes
        })
        
        expect(attrs.has_nat_route?).to eq(false)
      end
    end
  end
  
  describe "aws_route_table function behavior" do
    it "creates a resource reference with minimal attributes" do
      ref = test_instance.aws_route_table(:test, {
        vpc_id: vpc_id
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_route_table')
      expect(ref.name).to eq(:test)
    end
    
    it "creates a resource reference with routes" do
      ref = test_instance.aws_route_table(:public_rt, {
        vpc_id: vpc_id,
        routes: [
          {
            cidr_block: "0.0.0.0/0",
            gateway_id: igw_id
          }
        ]
      })
      
      expect(ref.resource_attributes[:routes].length).to eq(1)
      expect(ref.resource_attributes[:routes].first[:cidr_block]).to eq("0.0.0.0/0")
      expect(ref.resource_attributes[:routes].first[:gateway_id]).to eq(igw_id)
    end
    
    it "creates a resource reference with multiple routes" do
      ref = test_instance.aws_route_table(:multi_rt, {
        vpc_id: vpc_id,
        routes: [
          {
            cidr_block: "0.0.0.0/0",
            gateway_id: igw_id
          },
          {
            cidr_block: "10.1.0.0/16",
            vpc_peering_connection_id: "${aws_vpc_peering_connection.test.id}"
          }
        ]
      })
      
      routes = ref.resource_attributes[:routes]
      expect(routes.length).to eq(2)
      expect(routes[0][:cidr_block]).to eq("0.0.0.0/0")
      expect(routes[1][:cidr_block]).to eq("10.1.0.0/16")
    end
    
    it "handles tags correctly" do
      ref = test_instance.aws_route_table(:tagged_rt, {
        vpc_id: vpc_id,
        tags: { Name: "tagged-rt", Environment: "test" }
      })
      
      expect(ref.resource_attributes[:tags]).to eq({
        Name: "tagged-rt",
        Environment: "test"
      })
    end
    
    it "validates route attributes in function call" do
      expect {
        test_instance.aws_route_table(:invalid, {
          vpc_id: vpc_id,
          routes: [
            {
              cidr_block: "0.0.0.0/0"
              # Missing target
            }
          ]
        })
      }.to raise_error(Dry::Struct::Error, /Route must specify exactly one target/)
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_route_table(:test, { vpc_id: vpc_id })
      
      expected_outputs = [:id, :arn, :owner_id, :route_table_id]
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_route_table.test.")
      end
    end
  end
  
  describe "common route table patterns" do
    it "creates a public route table with internet gateway" do
      ref = test_instance.aws_route_table(:public, {
        vpc_id: vpc_id,
        routes: [
          {
            cidr_block: "0.0.0.0/0",
            gateway_id: igw_id
          }
        ],
        tags: {
          Name: "public-route-table",
          Type: "public"
        }
      })
      
      routes = ref.resource_attributes[:routes]
      expect(routes.length).to eq(1)
      expect(routes.first[:cidr_block]).to eq("0.0.0.0/0")
      expect(routes.first[:gateway_id]).to eq(igw_id)
      expect(ref.resource_attributes[:tags][:Type]).to eq("public")
    end
    
    it "creates a private route table with NAT gateway" do
      ref = test_instance.aws_route_table(:private, {
        vpc_id: vpc_id,
        routes: [
          {
            cidr_block: "0.0.0.0/0",
            nat_gateway_id: nat_id
          }
        ],
        tags: {
          Name: "private-route-table",
          Type: "private"
        }
      })
      
      routes = ref.resource_attributes[:routes]
      expect(routes.length).to eq(1)
      expect(routes.first[:cidr_block]).to eq("0.0.0.0/0")
      expect(routes.first[:nat_gateway_id]).to eq(nat_id)
      expect(ref.resource_attributes[:tags][:Type]).to eq("private")
    end
    
    it "creates a route table for VPC peering" do
      ref = test_instance.aws_route_table(:peering, {
        vpc_id: vpc_id,
        routes: [
          {
            cidr_block: "10.1.0.0/16",
            vpc_peering_connection_id: "${aws_vpc_peering_connection.test.id}"
          },
          {
            cidr_block: "0.0.0.0/0",
            gateway_id: igw_id
          }
        ],
        tags: {
          Name: "peering-route-table",
          Purpose: "vpc-peering"
        }
      })
      
      routes = ref.resource_attributes[:routes]
      expect(routes.length).to eq(2)
      
      # Check peering route
      peering_route = routes.find { |r| r[:cidr_block] == "10.1.0.0/16" }
      expect(peering_route[:vpc_peering_connection_id]).to eq("${aws_vpc_peering_connection.test.id}")
      
      # Check internet route
      internet_route = routes.find { |r| r[:cidr_block] == "0.0.0.0/0" }
      expect(internet_route[:gateway_id]).to eq(igw_id)
    end
    
    it "creates a route table with IPv6 routes" do
      ref = test_instance.aws_route_table(:ipv6, {
        vpc_id: vpc_id,
        routes: [
          {
            ipv6_cidr_block: "::/0",
            egress_only_gateway_id: "${aws_egress_only_internet_gateway.test.id}"
          }
        ],
        tags: {
          Name: "ipv6-route-table",
          Version: "ipv6"
        }
      })
      
      routes = ref.resource_attributes[:routes]
      expect(routes.length).to eq(1)
      expect(routes.first[:ipv6_cidr_block]).to eq("::/0")
      expect(routes.first[:egress_only_gateway_id]).to eq("${aws_egress_only_internet_gateway.test.id}")
    end
    
    it "creates a route table with transit gateway routes" do
      ref = test_instance.aws_route_table(:transit, {
        vpc_id: vpc_id,
        routes: [
          {
            cidr_block: "192.168.0.0/16",
            transit_gateway_id: "${aws_ec2_transit_gateway.test.id}"
          },
          {
            cidr_block: "172.16.0.0/12",
            transit_gateway_id: "${aws_ec2_transit_gateway.test.id}"
          }
        ],
        tags: {
          Name: "transit-route-table",
          Purpose: "transit-gateway"
        }
      })
      
      routes = ref.resource_attributes[:routes]
      expect(routes.length).to eq(2)
      expect(routes.all? { |r| r[:transit_gateway_id] == "${aws_ec2_transit_gateway.test.id}" }).to eq(true)
    end
    
    it "creates an empty route table (only local routes)" do
      ref = test_instance.aws_route_table(:empty, {
        vpc_id: vpc_id,
        tags: { Name: "empty-route-table" }
      })
      
      expect(ref.resource_attributes[:routes]).to eq([])
      expect(ref.resource_attributes[:tags][:Name]).to eq("empty-route-table")
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_route_table(:test_rt, { 
        vpc_id: vpc_id,
        routes: [{ cidr_block: "0.0.0.0/0", gateway_id: igw_id }]
      })
      
      expect(ref.outputs[:id]).to eq("${aws_route_table.test_rt.id}")
      expect(ref.outputs[:arn]).to eq("${aws_route_table.test_rt.arn}")
      expect(ref.outputs[:owner_id]).to eq("${aws_route_table.test_rt.owner_id}")
      expect(ref.outputs[:route_table_id]).to eq("${aws_route_table.test_rt.id}")
    end
    
    it "can be used for subnet associations" do
      route_table_ref = test_instance.aws_route_table(:public, {
        vpc_id: vpc_id,
        routes: [{ cidr_block: "0.0.0.0/0", gateway_id: igw_id }]
      })
      
      # Simulate using route table reference in subnet association
      route_table_id = route_table_ref.outputs[:id]
      
      expect(route_table_id).to eq("${aws_route_table.public.id}")
    end
  end
end