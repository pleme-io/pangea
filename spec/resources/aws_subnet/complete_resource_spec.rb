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

# Load aws_subnet resource and types for testing
require 'pangea/resources/aws_subnet/resource'
require 'pangea/resources/aws_subnet/types'

RSpec.describe "aws_subnet resource function" do
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
  
  describe "Subnet attributes validation" do
    it "validates required vpc_id attribute" do
      expect {
        Pangea::Resources::AWS::SubnetAttributes.new({
          cidr_block: "10.0.1.0/24",
          availability_zone: "us-east-1a"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates required cidr_block attribute" do
      expect {
        Pangea::Resources::AWS::SubnetAttributes.new({
          vpc_id: vpc_id,
          availability_zone: "us-east-1a"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates required availability_zone attribute" do
      expect {
        Pangea::Resources::AWS::SubnetAttributes.new({
          vpc_id: vpc_id,
          cidr_block: "10.0.1.0/24"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "accepts valid subnet attributes" do
      attrs = Pangea::Resources::AWS::SubnetAttributes.new({
        vpc_id: vpc_id,
        cidr_block: "10.0.1.0/24",
        availability_zone: "us-east-1a"
      })
      
      expect(attrs.vpc_id).to eq(vpc_id)
      expect(attrs.cidr_block).to eq("10.0.1.0/24")
      expect(attrs.availability_zone).to eq("us-east-1a")
    end
    
    it "applies default for map_public_ip_on_launch" do
      attrs = Pangea::Resources::AWS::SubnetAttributes.new({
        vpc_id: vpc_id,
        cidr_block: "10.0.1.0/24",
        availability_zone: "us-east-1a"
      })
      
      expect(attrs.map_public_ip_on_launch).to eq(false)
    end
    
    it "accepts custom map_public_ip_on_launch" do
      attrs = Pangea::Resources::AWS::SubnetAttributes.new({
        vpc_id: vpc_id,
        cidr_block: "10.0.1.0/24", 
        availability_zone: "us-east-1a",
        map_public_ip_on_launch: true
      })
      
      expect(attrs.map_public_ip_on_launch).to eq(true)
    end
    
    it "applies default empty tags" do
      attrs = Pangea::Resources::AWS::SubnetAttributes.new({
        vpc_id: vpc_id,
        cidr_block: "10.0.1.0/24",
        availability_zone: "us-east-1a"
      })
      
      expect(attrs.tags).to eq({})
    end
    
    it "accepts custom tags" do
      attrs = Pangea::Resources::AWS::SubnetAttributes.new({
        vpc_id: vpc_id,
        cidr_block: "10.0.1.0/24",
        availability_zone: "us-east-1a",
        tags: { Name: "test-subnet", Type: "public" }
      })
      
      expect(attrs.tags).to eq({
        Name: "test-subnet",
        Type: "public"
      })
    end
    
    it "validates subnet CIDR block size range" do
      # Valid sizes (/16 to /28)
      [16, 20, 24, 28].each do |size|
        expect {
          Pangea::Resources::AWS::SubnetAttributes.new({
            vpc_id: vpc_id,
            cidr_block: "10.0.1.0/#{size}",
            availability_zone: "us-east-1a"
          })
        }.not_to raise_error
      end
    end
    
    it "rejects CIDR blocks that are too large (< /16)" do
      expect {
        Pangea::Resources::AWS::SubnetAttributes.new({
          vpc_id: vpc_id,
          cidr_block: "10.0.0.0/8",
          availability_zone: "us-east-1a"
        })
      }.to raise_error(Dry::Struct::Error, /between \/16 and \/28/)
    end
    
    it "rejects CIDR blocks that are too small (> /28)" do
      expect {
        Pangea::Resources::AWS::SubnetAttributes.new({
          vpc_id: vpc_id,
          cidr_block: "10.0.1.0/29",
          availability_zone: "us-east-1a"
        })
      }.to raise_error(Dry::Struct::Error, /between \/16 and \/28/)
    end
  end
  
  describe "aws_subnet function behavior" do
    it "creates a resource reference with valid attributes" do
      ref = test_instance.aws_subnet(:test, {
        vpc_id: vpc_id,
        cidr_block: "10.0.1.0/24",
        availability_zone: "us-east-1a"
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_subnet')
      expect(ref.name).to eq(:test)
    end
    
    it "applies default map_public_ip_on_launch in function call" do
      ref = test_instance.aws_subnet(:test, {
        vpc_id: vpc_id,
        cidr_block: "10.0.1.0/24",
        availability_zone: "us-east-1a"
      })
      
      expect(ref.resource_attributes[:map_public_ip_on_launch]).to eq(false)
    end
    
    it "accepts custom map_public_ip_on_launch in function call" do
      ref = test_instance.aws_subnet(:test, {
        vpc_id: vpc_id,
        cidr_block: "10.0.1.0/24",
        availability_zone: "us-east-1a",
        map_public_ip_on_launch: true
      })
      
      expect(ref.resource_attributes[:map_public_ip_on_launch]).to eq(true)
    end
    
    it "handles tags correctly in function call" do
      ref = test_instance.aws_subnet(:test, {
        vpc_id: vpc_id,
        cidr_block: "10.0.1.0/24",
        availability_zone: "us-east-1a",
        tags: { Name: "test-subnet", Type: "private" }
      })
      
      expect(ref.resource_attributes[:tags]).to eq({
        Name: "test-subnet",
        Type: "private"
      })
    end
    
    it "validates required attributes in function call" do
      expect {
        test_instance.aws_subnet(:test, {
          cidr_block: "10.0.1.0/24",
          availability_zone: "us-east-1a"
          # Missing vpc_id
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates CIDR block size in function call" do
      expect {
        test_instance.aws_subnet(:test, {
          vpc_id: vpc_id,
          cidr_block: "10.0.1.0/29",  # Too small
          availability_zone: "us-east-1a"
        })
      }.to raise_error(Dry::Struct::Error, /between \/16 and \/28/)
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_subnet(:test, {
        vpc_id: vpc_id,
        cidr_block: "10.0.1.0/24",
        availability_zone: "us-east-1a"
      })
      
      expected_outputs = [:id, :arn, :availability_zone, :availability_zone_id, 
                         :cidr_block, :vpc_id, :owner_id]
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_subnet.test.#{output}}")
      end
    end
    
    it "stores all provided attributes in resource_attributes" do
      ref = test_instance.aws_subnet(:test, {
        vpc_id: vpc_id,
        cidr_block: "10.0.1.0/24",
        availability_zone: "us-east-1a",
        map_public_ip_on_launch: true,
        tags: { Name: "test-subnet" }
      })
      
      expect(ref.resource_attributes[:vpc_id]).to eq(vpc_id)
      expect(ref.resource_attributes[:cidr_block]).to eq("10.0.1.0/24")
      expect(ref.resource_attributes[:availability_zone]).to eq("us-east-1a")
      expect(ref.resource_attributes[:map_public_ip_on_launch]).to eq(true)
      expect(ref.resource_attributes[:tags]).to eq({ Name: "test-subnet" })
    end
  end
  
  describe "subnet types and patterns" do
    it "creates a public subnet configuration" do
      ref = test_instance.aws_subnet(:public, {
        vpc_id: vpc_id,
        cidr_block: "10.0.1.0/24",
        availability_zone: "us-east-1a",
        map_public_ip_on_launch: true,
        tags: { Name: "public-subnet", Type: "public" }
      })
      
      expect(ref.resource_attributes[:map_public_ip_on_launch]).to eq(true)
      expect(ref.resource_attributes[:tags][:Type]).to eq("public")
    end
    
    it "creates a private subnet configuration" do
      ref = test_instance.aws_subnet(:private, {
        vpc_id: vpc_id,
        cidr_block: "10.0.2.0/24", 
        availability_zone: "us-east-1a",
        map_public_ip_on_launch: false,
        tags: { Name: "private-subnet", Type: "private" }
      })
      
      expect(ref.resource_attributes[:map_public_ip_on_launch]).to eq(false)
      expect(ref.resource_attributes[:tags][:Type]).to eq("private")
    end
    
    it "supports different subnet sizes" do
      # Test different common subnet sizes
      sizes = ["/24", "/25", "/26", "/27", "/28"]
      
      sizes.each do |size|
        ref = test_instance.aws_subnet(:"test_#{size.delete('/')}", {
          vpc_id: vpc_id,
          cidr_block: "10.0.1.0#{size}",
          availability_zone: "us-east-1a"
        })
        
        expect(ref.resource_attributes[:cidr_block]).to eq("10.0.1.0#{size}")
      end
    end
    
    it "supports multiple availability zones" do
      azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
      
      azs.each_with_index do |az, index|
        ref = test_instance.aws_subnet(:"subnet_#{index}", {
          vpc_id: vpc_id,
          cidr_block: "10.0.#{index + 1}.0/24",
          availability_zone: az
        })
        
        expect(ref.resource_attributes[:availability_zone]).to eq(az)
      end
    end
  end
end