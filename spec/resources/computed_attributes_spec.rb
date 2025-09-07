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

RSpec.describe "Computed Attributes - Pure Functions" do
  describe "VpcComputedAttributes" do
    it "detects RFC1918 private CIDR blocks" do
      private_cidrs = [
        '10.0.0.0/8',
        '10.255.255.0/24',
        '172.16.0.0/12',
        '172.31.255.0/24',
        '192.168.0.0/16',
        '192.168.255.0/24'
      ]
      
      private_cidrs.each do |cidr|
        vpc_ref = Pangea::Resources::ResourceReference.new(type: "aws_vpc", name: :test, resource_attributes: { cidr_block: cidr }, outputs: {})
        attrs = Pangea::Resources::VpcComputedAttributes.new(vpc_ref)
        expect(attrs.is_private_cidr?).to be true
      end
    end
    
    it "detects public CIDR blocks" do
      public_cidrs = [
        '8.8.8.0/24',
        '172.32.0.0/16',  # Just outside 172.16.0.0/12
        '192.169.0.0/16', # Just outside 192.168.0.0/16
        '11.0.0.0/8'
      ]
      
      public_cidrs.each do |cidr|
        vpc_ref = Pangea::Resources::ResourceReference.new(type: "aws_vpc", name: :test, resource_attributes: { cidr_block: cidr }, outputs: {})
        attrs = Pangea::Resources::VpcComputedAttributes.new(vpc_ref)
        expect(attrs.is_private_cidr?).to be false
      end
    end
    
    it "calculates subnet capacity correctly" do
      test_cases = [
        { cidr: '10.0.0.0/16', expected: 256 },    # 2^(24-16) = 256
        { cidr: '10.0.0.0/20', expected: 16 },     # 2^(24-20) = 16
        { cidr: '10.0.0.0/22', expected: 4 },      # 2^(24-22) = 4
        { cidr: '10.0.0.0/24', expected: 1 },      # 2^(24-24) = 1
        { cidr: '10.0.0.0/25', expected: 0 }       # Can't fit /24 in /25
      ]
      
      test_cases.each do |tc|
        vpc_ref = Pangea::Resources::ResourceReference.new(type: "aws_vpc", name: :test, resource_attributes: { cidr_block: tc[:cidr] }, outputs: {})
        attrs = Pangea::Resources::VpcComputedAttributes.new(vpc_ref)
        expect(attrs.estimated_subnet_capacity).to eq(tc[:expected])
      end
    end
  end

  describe "SubnetComputedAttributes" do
    it "identifies public subnets correctly" do
      subnet_ref = Pangea::Resources::ResourceReference.new(
        type: 'aws_subnet',
        name: :public,
        resource_attributes: { map_public_ip_on_launch: true },
        outputs: {}
      )
      public_subnet = Pangea::Resources::SubnetComputedAttributes.new(subnet_ref)
      
      expect(public_subnet.is_public?).to be true
      expect(public_subnet.is_private?).to be false
      expect(public_subnet.subnet_type).to eq('public')
    end
    
    it "identifies private subnets correctly" do
      subnet_ref = Pangea::Resources::ResourceReference.new(
        type: 'aws_subnet',
        name: :private,
        resource_attributes: { map_public_ip_on_launch: false },
        outputs: {}
      )
      private_subnet = Pangea::Resources::SubnetComputedAttributes.new(subnet_ref)
      
      expect(private_subnet.is_public?).to be false
      expect(private_subnet.is_private?).to be true
      expect(private_subnet.subnet_type).to eq('private')
    end
    
    it "defaults to private when map_public_ip_on_launch is nil" do
      subnet_ref = Pangea::Resources::ResourceReference.new(
        type: 'aws_subnet',
        name: :test,
        resource_attributes: { map_public_ip_on_launch: nil },
        outputs: {}
      )
      subnet = Pangea::Resources::SubnetComputedAttributes.new(subnet_ref)
      
      expect(subnet.is_private?).to be true
      expect(subnet.subnet_type).to eq('private')
    end
    
    it "calculates IP capacity correctly" do
      test_cases = [
        { cidr: '10.0.0.0/24', expected: 251 },    # 256 - 5 AWS reserved
        { cidr: '10.0.0.0/25', expected: 123 },    # 128 - 5 AWS reserved
        { cidr: '10.0.0.0/26', expected: 59 },     # 64 - 5 AWS reserved
        { cidr: '10.0.0.0/27', expected: 27 },     # 32 - 5 AWS reserved
        { cidr: '10.0.0.0/28', expected: 11 }      # 16 - 5 AWS reserved
      ]
      
      test_cases.each do |tc|
        subnet_ref = Pangea::Resources::ResourceReference.new(
          type: 'aws_subnet',
          name: :test,
          resource_attributes: { cidr_block: tc[:cidr] },
          outputs: {}
        )
        subnet = Pangea::Resources::SubnetComputedAttributes.new(subnet_ref)
        expect(subnet.ip_capacity).to eq(tc[:expected])
      end
    end
  end

  describe "InstanceComputedAttributes" do
    it "predicts public IP assignment correctly" do
      # Public subnet with default behavior
      instance_ref = Pangea::Resources::ResourceReference.new(
        type: 'aws_instance',
        name: :public,
        resource_attributes: {
          subnet_id: 'subnet-public',
          associate_public_ip_address: nil
        },
        outputs: {}
      )
      public_instance = Pangea::Resources::InstanceComputedAttributes.new(instance_ref)
      expect(public_instance.will_have_public_ip?).to be true
      
      # Private subnet with explicit public IP
      instance_ref = Pangea::Resources::ResourceReference.new(
        type: 'aws_instance',
        name: :private_with_public,
        resource_attributes: {
          subnet_id: 'subnet-private',
          associate_public_ip_address: true
        },
        outputs: {}
      )
      private_with_public = Pangea::Resources::InstanceComputedAttributes.new(instance_ref)
      expect(private_with_public.will_have_public_ip?).to be true
      
      # Public subnet with explicitly disabled public IP
      instance_ref = Pangea::Resources::ResourceReference.new(
        type: 'aws_instance',
        name: :public_without_ip,
        resource_attributes: {
          subnet_id: 'subnet-public',
          associate_public_ip_address: false
        },
        outputs: {}
      )
      public_without_ip = Pangea::Resources::InstanceComputedAttributes.new(instance_ref)
      expect(public_without_ip.will_have_public_ip?).to be false
    end
    
    it "extracts compute family correctly" do
      test_cases = [
        { type: 't3.micro', family: 't3' },
        { type: 'm5.large', family: 'm5' },
        { type: 'c5n.xlarge', family: 'c5n' },
        { type: 'r6i.2xlarge', family: 'r6i' },
        { type: 'x2gd.medium', family: 'x2gd' }
      ]
      
      test_cases.each do |tc|
        instance_ref = Pangea::Resources::ResourceReference.new(
          type: 'aws_instance',
          name: :test,
          resource_attributes: { instance_type: tc[:type] },
          outputs: {}
        )
        instance = Pangea::Resources::InstanceComputedAttributes.new(instance_ref)
        expect(instance.compute_family).to eq(tc[:family])
      end
    end
    
    it "extracts compute size correctly" do
      test_cases = [
        { type: 't3.micro', size: 'micro' },
        { type: 'm5.large', size: 'large' },
        { type: 'c5n.xlarge', size: 'xlarge' },
        { type: 'r6i.2xlarge', size: '2xlarge' },
        { type: 'x2gd.medium', size: 'medium' }
      ]
      
      test_cases.each do |tc|
        instance_ref = Pangea::Resources::ResourceReference.new(
          type: 'aws_instance',
          name: :test,
          resource_attributes: { instance_type: tc[:type] },
          outputs: {}
        )
        instance = Pangea::Resources::InstanceComputedAttributes.new(instance_ref)
        expect(instance.compute_size).to eq(tc[:size])
      end
    end
    
    it "handles nil instance type gracefully" do
      instance_ref = Pangea::Resources::ResourceReference.new(
        type: 'aws_instance',
        name: :test,
        resource_attributes: { instance_type: nil },
        outputs: {}
      )
      instance = Pangea::Resources::InstanceComputedAttributes.new(instance_ref)
      
      expect(instance.compute_family).to be_nil
      expect(instance.compute_size).to be_nil
    end
  end
end