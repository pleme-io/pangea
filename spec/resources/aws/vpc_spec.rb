# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "AWS VPC Resource Functions" do
  describe "VpcAttributes type validation" do
    it "creates valid VPC with required attributes" do
      vpc_attrs = Pangea::Resources::AWS::Types::VpcAttributes.new(
        cidr_block: "10.0.0.0/16",
        tags: { Name: "test-vpc" }
      )
      
      expect(vpc_attrs.cidr_block).to eq("10.0.0.0/16")
      expect(vpc_attrs.enable_dns_hostnames).to be true # default
      expect(vpc_attrs.enable_dns_support).to be true # default
      expect(vpc_attrs.instance_tenancy).to eq("default")
      expect(vpc_attrs.tags[:Name]).to eq("test-vpc")
    end
    
    it "computes RFC1918 private CIDR correctly" do
      # Test 10.x.x.x/16 (RFC1918)
      vpc_10 = Pangea::Resources::AWS::Types::VpcAttributes.new(cidr_block: "10.0.0.0/16")
      expect(vpc_10.is_rfc1918_private?).to be true
      
      # Test 172.16.x.x/12 (RFC1918)
      vpc_172 = Pangea::Resources::AWS::Types::VpcAttributes.new(cidr_block: "172.16.0.0/16")
      expect(vpc_172.is_rfc1918_private?).to be true
      
      # Test 192.168.x.x/16 (RFC1918)
      vpc_192 = Pangea::Resources::AWS::Types::VpcAttributes.new(cidr_block: "192.168.1.0/24")
      expect(vpc_192.is_rfc1918_private?).to be true
      
      # Test public CIDR (not RFC1918)
      vpc_public = Pangea::Resources::AWS::Types::VpcAttributes.new(cidr_block: "203.0.113.0/24")
      expect(vpc_public.is_rfc1918_private?).to be false
    end
    
    it "estimates subnet capacity correctly" do
      # /16 VPC should estimate 256 /24 subnets
      vpc_16 = Pangea::Resources::AWS::Types::VpcAttributes.new(cidr_block: "10.0.0.0/16")
      expect(vpc_16.subnet_count_estimate).to eq(256)
      
      # /20 VPC should estimate 16 /24 subnets  
      vpc_20 = Pangea::Resources::AWS::Types::VpcAttributes.new(cidr_block: "10.0.0.0/20")
      expect(vpc_20.subnet_count_estimate).to eq(16)
      
      # /24 VPC should estimate 1 /24 subnet
      vpc_24 = Pangea::Resources::AWS::Types::VpcAttributes.new(cidr_block: "10.0.0.0/24")
      expect(vpc_24.subnet_count_estimate).to eq(1)
    end
    
    it "validates CIDR block size constraints" do
      # Test CIDR too small (>/28)
      expect {
        Pangea::Resources::AWS::Types::VpcAttributes.new(cidr_block: "10.0.0.0/30")
      }.to raise_error(Dry::Struct::Error, /too small/)
      
      # Test CIDR too large (</16) 
      expect {
        Pangea::Resources::AWS::Types::VpcAttributes.new(cidr_block: "10.0.0.0/12") 
      }.to raise_error(Dry::Struct::Error, /too large/)
      
      # Test edge cases that should work
      expect {
        Pangea::Resources::AWS::Types::VpcAttributes.new(cidr_block: "10.0.0.0/16") # minimum
      }.not_to raise_error
      
      expect {
        Pangea::Resources::AWS::Types::VpcAttributes.new(cidr_block: "10.0.0.0/28") # maximum
      }.not_to raise_error
    end
    
    it "applies defaults for optional attributes" do
      minimal_vpc = Pangea::Resources::AWS::Types::VpcAttributes.new(
        cidr_block: "10.0.0.0/16"
      )
      
      expect(minimal_vpc.enable_dns_hostnames).to be true
      expect(minimal_vpc.enable_dns_support).to be true 
      expect(minimal_vpc.instance_tenancy).to eq("default")
      expect(minimal_vpc.tags).to eq({})
    end
    
    it "allows override of defaults" do
      custom_vpc = Pangea::Resources::AWS::Types::VpcAttributes.new(
        cidr_block: "10.0.0.0/16",
        enable_dns_hostnames: false,
        enable_dns_support: false,
        instance_tenancy: "dedicated",
        tags: { Environment: "production", CostCenter: "engineering" }
      )
      
      expect(custom_vpc.enable_dns_hostnames).to be false
      expect(custom_vpc.enable_dns_support).to be false
      expect(custom_vpc.instance_tenancy).to eq("dedicated")
      expect(custom_vpc.tags[:Environment]).to eq("production")
      expect(custom_vpc.tags[:CostCenter]).to eq("engineering")
    end
  end
  
  describe "Pure functional validation" do
    it "produces consistent results for same input" do
      attrs = { cidr_block: "10.0.0.0/16", tags: { Name: "test" } }
      
      # Create the same VPC multiple times
      vpc1 = Pangea::Resources::AWS::Types::VpcAttributes.new(attrs)
      vpc2 = Pangea::Resources::AWS::Types::VpcAttributes.new(attrs)
      
      # Should produce identical objects (pure function property)
      expect(vpc1.cidr_block).to eq(vpc2.cidr_block)
      expect(vpc1.enable_dns_hostnames).to eq(vpc2.enable_dns_hostnames)
      expect(vpc1.instance_tenancy).to eq(vpc2.instance_tenancy)
      expect(vpc1.is_rfc1918_private?).to eq(vpc2.is_rfc1918_private?)
      expect(vpc1.subnet_count_estimate).to eq(vpc2.subnet_count_estimate)
    end
    
    it "has no side effects during creation" do
      original_attrs = { cidr_block: "10.0.0.0/16", tags: { Name: "test" } }
      attrs_copy = original_attrs.dup
      
      # Create VPC (should not modify input)
      _vpc = Pangea::Resources::AWS::Types::VpcAttributes.new(attrs_copy)
      
      # Original attributes should be unchanged (no side effects)
      expect(attrs_copy).to eq(original_attrs)
    end
  end
end