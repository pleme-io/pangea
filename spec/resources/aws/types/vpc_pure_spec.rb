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

RSpec.describe "VpcAttributes - Pure Functions" do
  describe "CIDR validation in constructor" do
    it "accepts valid CIDR blocks within size constraints" do
      valid_cidrs = [
        '10.0.0.0/16',  # Exactly /16
        '10.0.0.0/20',  # Mid-range
        '10.0.0.0/24',  # Common size
        '10.0.0.0/28'   # Exactly /28
      ]
      
      valid_cidrs.each do |cidr|
        vpc = Pangea::Resources::AWS::Types::VpcAttributes.new(
          cidr_block: cidr,
          tags: { Name: 'test' }
        )
        expect(vpc.cidr_block).to eq(cidr)
      end
    end
    
    it "rejects CIDR blocks that are too large" do
      large_cidrs = ['10.0.0.0/8', '10.0.0.0/12', '10.0.0.0/15']
      
      large_cidrs.each do |cidr|
        expect {
          Pangea::Resources::AWS::Types::VpcAttributes.new(
            cidr_block: cidr,
            tags: { Name: 'test' }
          )
        }.to raise_error(Dry::Struct::Error, /too large/)
      end
    end
    
    it "rejects CIDR blocks that are too small" do
      small_cidrs = ['10.0.0.0/29', '10.0.0.0/30', '10.0.0.0/32']
      
      small_cidrs.each do |cidr|
        expect {
          Pangea::Resources::AWS::Types::VpcAttributes.new(
            cidr_block: cidr,
            tags: { Name: 'test' }
          )
        }.to raise_error(Dry::Struct::Error, /too small/)
      end
    end
  end

  describe "#subnet_count_estimate" do
    it "calculates subnet capacity for different VPC sizes" do
      test_cases = [
        { cidr: '10.0.0.0/16', expected: 256 },    # Can fit 256 /24 subnets
        { cidr: '10.0.0.0/20', expected: 16 },     # Can fit 16 /24 subnets
        { cidr: '10.0.0.0/22', expected: 4 },      # Can fit 4 /24 subnets
        { cidr: '10.0.0.0/24', expected: 1 },      # Exactly one /24
        { cidr: '10.0.0.0/25', expected: 0 },      # Can't fit a /24
        { cidr: '10.0.0.0/28', expected: 0 }       # Too small for /24
      ]
      
      test_cases.each do |tc|
        vpc = Pangea::Resources::AWS::Types::VpcAttributes.new(
          cidr_block: tc[:cidr],
          tags: { Name: 'test' }
        )
        expect(vpc.subnet_count_estimate).to eq(tc[:expected])
      end
    end
  end

  describe "#is_rfc1918_private?" do
    it "correctly identifies RFC1918 private address spaces" do
      private_cidrs = [
        '10.0.0.0/16',      # Class A private
        '10.255.0.0/16',    # Class A private
        '172.16.0.0/16',    # Class B private start
        '172.31.0.0/16',    # Class B private end
        '192.168.0.0/16',   # Class C private
        '192.168.100.0/24'  # Class C private subnet
      ]
      
      private_cidrs.each do |cidr|
        vpc = Pangea::Resources::AWS::Types::VpcAttributes.new(
          cidr_block: cidr,
          tags: { Name: 'test' }
        )
        expect(vpc.is_rfc1918_private?).to be true
      end
    end
    
    it "correctly identifies public CIDR blocks" do
      public_cidrs = [
        '8.8.8.0/24',      # Google DNS range
        '172.32.0.0/16',   # Just outside private range
        '192.169.0.0/16',  # Just outside private range
        '11.0.0.0/16',     # Public IP space
        '1.1.1.0/24'       # Cloudflare DNS range
      ]
      
      public_cidrs.each do |cidr|
        vpc = Pangea::Resources::AWS::Types::VpcAttributes.new(
          cidr_block: cidr,
          tags: { Name: 'test' }
        )
        expect(vpc.is_rfc1918_private?).to be false
      end
    end
  end

  describe "default values" do
    it "provides sensible defaults for optional attributes" do
      vpc = Pangea::Resources::AWS::Types::VpcAttributes.new(
        cidr_block: '10.0.0.0/16',
        tags: { Name: 'test' }
      )
      
      expect(vpc.enable_dns_support).to be true
      expect(vpc.enable_dns_hostnames).to be true
      expect(vpc.instance_tenancy).to eq('default')
    end
    
    it "allows overriding defaults" do
      vpc = Pangea::Resources::AWS::Types::VpcAttributes.new(
        cidr_block: '10.0.0.0/16',
        enable_dns_support: false,
        enable_dns_hostnames: false,
        instance_tenancy: 'dedicated',
        tags: { Name: 'test' }
      )
      
      expect(vpc.enable_dns_support).to be false
      expect(vpc.enable_dns_hostnames).to be false
      expect(vpc.instance_tenancy).to eq('dedicated')
    end
  end

  describe "immutability" do
    it "creates immutable VpcAttributes objects" do
      vpc = Pangea::Resources::AWS::Types::VpcAttributes.new(
        cidr_block: '10.0.0.0/16',
        tags: { Name: 'test' }
      )
      
      expect(vpc).to be_frozen
      expect { vpc.instance_variable_set(:@cidr_block, '10.1.0.0/16') }.to raise_error(FrozenError)
    end
  end

  describe "tag handling" do
    it "accepts complex tag structures" do
      vpc = Pangea::Resources::AWS::Types::VpcAttributes.new(
        cidr_block: '10.0.0.0/16',
        tags: {
          Name: 'production-vpc',
          Environment: 'production',
          CostCenter: '12345'
        }
      )
      
      expect(vpc.tags[:Name]).to eq('production-vpc')
      expect(vpc.tags[:Environment]).to eq('production')
      expect(vpc.tags[:CostCenter]).to eq('12345')
    end
  end
end