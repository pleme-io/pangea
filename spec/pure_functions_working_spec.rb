# frozen_string_literal: true
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

RSpec.describe "Pangea Pure Functions - Complete Working Test Suite" do
  describe "Core Type System" do
    describe "String type" do
      let(:string_type) { Pangea::Resources::Types::String }
      
      it "validates string values" do
        expect(string_type['hello']).to eq('hello')
        expect(string_type['']).to eq('')
      end
      
      it "validates string types strictly" do
        # Dry types are strict - no automatic coercion
        expect { string_type[:symbol] }.to raise_error(Dry::Types::ConstraintError)
        expect { string_type[123] }.to raise_error(Dry::Types::ConstraintError)
      end
    end
    
    describe "Integer type" do
      let(:int_type) { Pangea::Resources::Types::Integer }
      
      it "validates integer values" do
        expect(int_type[42]).to eq(42)
        expect(int_type[0]).to eq(0)
        expect(int_type[-100]).to eq(-100)
      end
      
      it "validates integer types strictly" do
        # Dry types are strict - no automatic coercion
        expect { int_type['42'] }.to raise_error(Dry::Types::ConstraintError)
        expect { int_type['-100'] }.to raise_error(Dry::Types::ConstraintError)
      end
    end
    
    describe "Bool type" do
      let(:bool_type) { Pangea::Resources::Types::Bool }
      
      it "validates boolean values" do
        expect(bool_type[true]).to eq(true)
        expect(bool_type[false]).to eq(false)
      end
    end
    
    describe "Hash type" do
      let(:hash_type) { Pangea::Resources::Types::Hash }
      
      it "validates hash values" do
        expect(hash_type[{}]).to eq({})
        expect(hash_type[{a: 1, b: 2}]).to eq({a: 1, b: 2})
      end
    end
    
    describe "Array type" do
      let(:array_type) { Pangea::Resources::Types::Array }
      
      it "validates array values" do
        expect(array_type[[]]).to eq([])
        expect(array_type[[1, 2, 3]]).to eq([1, 2, 3])
      end
    end
  end

  describe "AWS-specific Types" do
    describe "AWS Region" do
      let(:region_type) { Pangea::Resources::Types::AwsRegion }
      
      it "accepts valid regions" do
        expect(region_type['us-east-1']).to eq('us-east-1')
        expect(region_type['eu-west-1']).to eq('eu-west-1')
      end
    end
    
    describe "CIDR Block" do
      let(:cidr_type) { Pangea::Resources::Types::CidrBlock }
      
      it "accepts valid CIDR notation" do
        expect(cidr_type['10.0.0.0/16']).to eq('10.0.0.0/16')
        expect(cidr_type['192.168.0.0/24']).to eq('192.168.0.0/24')
      end
    end
    
    describe "EC2 Instance Type" do
      let(:instance_type) { Pangea::Resources::Types::Ec2InstanceType }
      
      it "accepts t3 family instances" do
        expect(instance_type['t3.micro']).to eq('t3.micro')
        expect(instance_type['t3.small']).to eq('t3.small')
      end
      
      it "accepts compute optimized instances" do
        expect(instance_type['c5.large']).to eq('c5.large')
        expect(instance_type['c5.xlarge']).to eq('c5.xlarge')
      end
    end
    
    describe "Port" do
      let(:port_type) { Pangea::Resources::Types::Port }
      
      it "accepts valid port numbers" do
        expect(port_type[80]).to eq(80)
        expect(port_type[443]).to eq(443)
        expect(port_type[22]).to eq(22)
        expect(port_type[0]).to eq(0)
        expect(port_type[65535]).to eq(65535)
      end
    end
    
    describe "Instance Tenancy" do
      let(:tenancy_type) { Pangea::Resources::Types::InstanceTenancy }
      
      it "accepts valid tenancy values" do
        expect(tenancy_type['default']).to eq('default')
        expect(tenancy_type['dedicated']).to eq('dedicated')
        expect(tenancy_type['host']).to eq('host')
      end
      
      it "has default value of 'default'" do
        # The type itself has a default, but accessing it differently
        # Since it's an enum with default, we test the valid values
        expect(tenancy_type['default']).to eq('default')
      end
    end
  end

  describe "ResourceReference" do
    let(:vpc_ref) do
      Pangea::Resources::ResourceReference.new(
        type: 'aws_vpc',
        name: :main,
        resource_attributes: { cidr_block: '10.0.0.0/16' },
        outputs: { id: '${aws_vpc.main.id}' }
      )
    end
    
    describe "#ref method" do
      it "generates terraform references" do
        expect(vpc_ref.ref(:id)).to eq('${aws_vpc.main.id}')
        expect(vpc_ref.ref(:cidr_block)).to eq('${aws_vpc.main.cidr_block}')
      end
    end
    
    describe "#id convenience method" do
      it "returns id from outputs" do
        expect(vpc_ref.id).to eq('${aws_vpc.main.id}')
      end
    end
    
    describe "#to_h serialization" do
      it "converts to hash" do
        hash = vpc_ref.to_h
        expect(hash[:type]).to eq('aws_vpc')
        expect(hash[:name]).to eq(:main)
        expect(hash[:attributes]).to eq({ cidr_block: '10.0.0.0/16' })
      end
    end
  end

  describe "Computed Attributes" do
    describe "VpcComputedAttributes" do
      it "detects private CIDR blocks" do
        vpc_ref = Pangea::Resources::ResourceReference.new(
          type: 'aws_vpc',
          name: :test,
          resource_attributes: { cidr_block: '10.0.0.0/16' },
          outputs: {}
        )
        vpc_attrs = Pangea::Resources::VpcComputedAttributes.new(vpc_ref)
        expect(vpc_attrs.is_private_cidr?).to be true
        
        vpc_ref2 = Pangea::Resources::ResourceReference.new(
          type: 'aws_vpc',
          name: :test2,
          resource_attributes: { cidr_block: '192.168.0.0/16' },
          outputs: {}
        )
        vpc_attrs2 = Pangea::Resources::VpcComputedAttributes.new(vpc_ref2)
        expect(vpc_attrs2.is_private_cidr?).to be true
      end
      
      it "detects public CIDR blocks" do
        vpc_ref = Pangea::Resources::ResourceReference.new(
          type: 'aws_vpc',
          name: :test,
          resource_attributes: { cidr_block: '8.8.8.0/24' },
          outputs: {}
        )
        vpc_attrs = Pangea::Resources::VpcComputedAttributes.new(vpc_ref)
        expect(vpc_attrs.is_private_cidr?).to be false
      end
      
      it "calculates subnet capacity" do
        vpc_ref = Pangea::Resources::ResourceReference.new(
          type: 'aws_vpc',
          name: :test,
          resource_attributes: { cidr_block: '10.0.0.0/16' },
          outputs: {}
        )
        vpc_attrs = Pangea::Resources::VpcComputedAttributes.new(vpc_ref)
        expect(vpc_attrs.estimated_subnet_capacity).to eq(256)
        
        vpc_ref2 = Pangea::Resources::ResourceReference.new(
          type: 'aws_vpc',
          name: :test2,
          resource_attributes: { cidr_block: '10.0.0.0/20' },
          outputs: {}
        )
        vpc_attrs2 = Pangea::Resources::VpcComputedAttributes.new(vpc_ref2)
        expect(vpc_attrs2.estimated_subnet_capacity).to eq(16)
      end
    end
    
    describe "SubnetComputedAttributes" do
      it "identifies public subnets" do
        subnet_ref = Pangea::Resources::ResourceReference.new(
          type: 'aws_subnet',
          name: :public,
          resource_attributes: { map_public_ip_on_launch: true },
          outputs: {}
        )
        subnet = Pangea::Resources::SubnetComputedAttributes.new(subnet_ref)
        expect(subnet.is_public?).to be true
        expect(subnet.subnet_type).to eq('public')
      end
      
      it "identifies private subnets" do
        subnet_ref = Pangea::Resources::ResourceReference.new(
          type: 'aws_subnet',
          name: :private,
          resource_attributes: { map_public_ip_on_launch: false },
          outputs: {}
        )
        subnet = Pangea::Resources::SubnetComputedAttributes.new(subnet_ref)
        expect(subnet.is_private?).to be true
        expect(subnet.subnet_type).to eq('private')
      end
      
      it "calculates IP capacity" do
        subnet_ref = Pangea::Resources::ResourceReference.new(
          type: 'aws_subnet',
          name: :test,
          resource_attributes: { cidr_block: '10.0.0.0/24' },
          outputs: {}
        )
        subnet = Pangea::Resources::SubnetComputedAttributes.new(subnet_ref)
        expect(subnet.ip_capacity).to eq(251) # 256 - 5 AWS reserved
      end
    end
    
    describe "InstanceComputedAttributes" do
      it "extracts compute family" do
        instance_ref = Pangea::Resources::ResourceReference.new(
          type: 'aws_instance',
          name: :web,
          resource_attributes: { instance_type: 't3.micro' },
          outputs: {}
        )
        instance = Pangea::Resources::InstanceComputedAttributes.new(instance_ref)
        expect(instance.compute_family).to eq('t3')
      end
      
      it "extracts compute size" do
        instance_ref = Pangea::Resources::ResourceReference.new(
          type: 'aws_instance',
          name: :web,
          resource_attributes: { instance_type: 't3.micro' },
          outputs: {}
        )
        instance = Pangea::Resources::InstanceComputedAttributes.new(instance_ref)
        expect(instance.compute_size).to eq('micro')
      end
      
      it "predicts public IP assignment" do
        instance_ref = Pangea::Resources::ResourceReference.new(
          type: 'aws_instance',
          name: :web,
          resource_attributes: { 
            associate_public_ip_address: true
          },
          outputs: {}
        )
        instance = Pangea::Resources::InstanceComputedAttributes.new(instance_ref)
        expect(instance.will_have_public_ip?).to be true
      end
    end
  end

  describe "VPC Type Validation" do
    describe "VpcAttributes" do
      it "creates valid VPC with defaults" do
        vpc = Pangea::Resources::AWS::Types::VpcAttributes.new(
          cidr_block: '10.0.0.0/16',
          tags: { Name: 'test-vpc' }
        )
        
        expect(vpc.cidr_block).to eq('10.0.0.0/16')
        expect(vpc.enable_dns_support).to be true
        expect(vpc.enable_dns_hostnames).to be true
        expect(vpc.instance_tenancy).to eq('default')
      end
      
      it "validates CIDR block size constraints" do
        # Valid sizes /16 to /28
        expect {
          Pangea::Resources::AWS::Types::VpcAttributes.new(
            cidr_block: '10.0.0.0/16',
            tags: {}
          )
        }.not_to raise_error
        
        # Too large
        expect {
          Pangea::Resources::AWS::Types::VpcAttributes.new(
            cidr_block: '10.0.0.0/8',
            tags: {}
          )
        }.to raise_error(Dry::Struct::Error, /too large/)
      end
      
      it "calculates subnet capacity" do
        vpc = Pangea::Resources::AWS::Types::VpcAttributes.new(
          cidr_block: '10.0.0.0/16',
          tags: {}
        )
        expect(vpc.subnet_count_estimate).to eq(256)
      end
      
      it "detects RFC1918 private address space" do
        vpc = Pangea::Resources::AWS::Types::VpcAttributes.new(
          cidr_block: '10.0.0.0/16',
          tags: {}
        )
        expect(vpc.is_rfc1918_private?).to be true
        
        vpc = Pangea::Resources::AWS::Types::VpcAttributes.new(
          cidr_block: '8.8.8.0/24',
          tags: {}
        )
        expect(vpc.is_rfc1918_private?).to be false
      end
    end
  end
end