# frozen_string_literal: true

require_relative '../../../spec_helper'

RSpec.describe Pangea::Resources::AWS::Types::VpcAttributes do
  describe "type validation and creation" do
    it "creates valid VPC with required attributes" do
      vpc_attrs = described_class.new(
        cidr_block: "10.0.0.0/16",
        tags: { Name: "test-vpc" }
      )
      
      expect(vpc_attrs.cidr_block).to eq("10.0.0.0/16")
      expect(vpc_attrs.enable_dns_hostnames).to be true # default
      expect(vpc_attrs.enable_dns_support).to be true # default  
      expect(vpc_attrs.instance_tenancy).to eq("default")
      expect(vpc_attrs.tags[:Name]).to eq("test-vpc")
    end

    it "creates VPC with minimal attributes" do
      vpc_attrs = described_class.new(cidr_block: "192.168.0.0/16")
      
      expect(vpc_attrs.cidr_block).to eq("192.168.0.0/16")
      expect(vpc_attrs.enable_dns_hostnames).to be true
      expect(vpc_attrs.enable_dns_support).to be true
      expect(vpc_attrs.instance_tenancy).to eq("default")
      expect(vpc_attrs.tags).to eq({})
    end
    
    it "allows override of default values" do
      vpc_attrs = described_class.new(
        cidr_block: "10.0.0.0/16",
        enable_dns_hostnames: false,
        enable_dns_support: false,
        instance_tenancy: "dedicated",
        tags: { Environment: "production", CostCenter: "engineering" }
      )
      
      expect(vpc_attrs.enable_dns_hostnames).to be false
      expect(vpc_attrs.enable_dns_support).to be false
      expect(vpc_attrs.instance_tenancy).to eq("dedicated")
      expect(vpc_attrs.tags[:Environment]).to eq("production")
      expect(vpc_attrs.tags[:CostCenter]).to eq("engineering")
    end

    it "accepts all valid instance tenancy values" do
      %w[default dedicated host].each do |tenancy|
        vpc_attrs = described_class.new(
          cidr_block: "10.0.0.0/16",
          instance_tenancy: tenancy
        )
        expect(vpc_attrs.instance_tenancy).to eq(tenancy)
      end
    end

    it "handles complex tag structures" do
      tags = {
        Name: "production-vpc",
        Environment: "prod", 
        Team: "platform",
        CostCenter: "engineering",
        Project: "infrastructure",
        ManagedBy: "pangea"
      }
      
      vpc_attrs = described_class.new(
        cidr_block: "10.0.0.0/16",
        tags: tags
      )
      
      expect(vpc_attrs.tags).to eq(tags)
      expect(vpc_attrs.tags.keys).to contain_exactly(:Name, :Environment, :Team, :CostCenter, :Project, :ManagedBy)
    end
  end

  describe "CIDR block validation" do
    it "accepts valid CIDR blocks at boundary sizes" do
      valid_cidrs = [
        "10.0.0.0/16",  # minimum size
        "10.0.0.0/20", 
        "10.0.0.0/24",
        "10.0.0.0/28"   # maximum size
      ]
      
      valid_cidrs.each do |cidr|
        expect {
          described_class.new(cidr_block: cidr)
        }.not_to raise_error
      end
    end

    it "rejects CIDR blocks that are too small" do
      invalid_small_cidrs = ["10.0.0.0/30", "10.0.0.0/32"]
      
      invalid_small_cidrs.each do |cidr|
        expect {
          described_class.new(cidr_block: cidr)
        }.to raise_error(Dry::Struct::Error, /too small/)
      end
    end

    it "rejects CIDR blocks that are too large" do  
      invalid_large_cidrs = ["10.0.0.0/8", "10.0.0.0/12", "10.0.0.0/15"]
      
      invalid_large_cidrs.each do |cidr|
        expect {
          described_class.new(cidr_block: cidr)
        }.to raise_error(Dry::Struct::Error, /too large/)
      end
    end

    it "validates CIDR format with Resources::Types::CidrBlock" do
      invalid_formats = [
        "not-a-cidr",
        "10.0.0/16",
        "10.0.0.0",
        "256.0.0.0/16",
        "10.0.0.0/33"
      ]
      
      invalid_formats.each do |invalid_cidr|
        expect {
          described_class.new(cidr_block: invalid_cidr)
        }.to raise_error(Dry::Types::ConstraintError)
      end
    end
  end

  describe "RFC1918 private CIDR detection" do
    it "correctly identifies RFC1918 private address spaces" do
      private_cidrs = {
        "10.0.0.0/16" => true,      # Class A private
        "10.255.255.0/24" => true,  # Class A private boundary
        "172.16.0.0/16" => true,    # Class B private start
        "172.31.255.0/24" => true,  # Class B private end
        "192.168.1.0/24" => true,   # Class C private
        "192.168.255.0/28" => true  # Class C private boundary
      }
      
      private_cidrs.each do |cidr, expected_private|
        vpc_attrs = described_class.new(cidr_block: cidr)
        expect(vpc_attrs.is_rfc1918_private?).to eq(expected_private), 
          "Expected #{cidr} to be private: #{expected_private}"
      end
    end

    it "correctly identifies public CIDR blocks" do
      public_cidrs = [
        "203.0.113.0/24",   # RFC5737 TEST-NET-3
        "8.8.8.0/24",       # Google DNS
        "1.1.1.0/24",       # Cloudflare DNS
        "172.15.255.0/24",  # Just below private range
        "172.32.0.0/24",    # Just above private range  
        "192.167.255.0/24", # Just below private range
        "192.169.0.0/24"    # Just above private range
      ]
      
      public_cidrs.each do |cidr|
        vpc_attrs = described_class.new(cidr_block: cidr)
        expect(vpc_attrs.is_rfc1918_private?).to be false,
          "Expected #{cidr} to be public"
      end
    end

    it "handles edge cases in private detection" do
      edge_cases = {
        "172.16.0.0/28" => true,    # Exact start of Class B private
        "172.31.255.255/32" => true, # Exact end of Class B private (conceptually)
        "10.0.0.1/32" => true,      # Single IP in Class A private
        "192.168.0.1/32" => true    # Single IP in Class C private
      }
      
      edge_cases.each do |cidr, expected_private|
        vpc_attrs = described_class.new(cidr_block: cidr)
        expect(vpc_attrs.is_rfc1918_private?).to eq(expected_private),
          "Edge case #{cidr} should be private: #{expected_private}"
      end
    end
  end

  describe "subnet capacity estimation" do
    it "estimates /24 subnet capacity correctly for different VPC sizes" do
      subnet_estimates = {
        "10.0.0.0/16" => 256,  # 65536 IPs total, 256 /24 subnets
        "10.0.0.0/17" => 128,  # 32768 IPs total, 128 /24 subnets
        "10.0.0.0/18" => 64,   # 16384 IPs total, 64 /24 subnets
        "10.0.0.0/19" => 32,   # 8192 IPs total, 32 /24 subnets
        "10.0.0.0/20" => 16,   # 4096 IPs total, 16 /24 subnets
        "10.0.0.0/21" => 8,    # 2048 IPs total, 8 /24 subnets
        "10.0.0.0/22" => 4,    # 1024 IPs total, 4 /24 subnets
        "10.0.0.0/23" => 2,    # 512 IPs total, 2 /24 subnets
        "10.0.0.0/24" => 1,    # 256 IPs total, 1 /24 subnet
        "10.0.0.0/28" => 0     # 16 IPs total, 0 /24 subnets possible
      }
      
      subnet_estimates.each do |cidr, expected_count|
        vpc_attrs = described_class.new(cidr_block: cidr)
        expect(vpc_attrs.subnet_count_estimate).to eq(expected_count),
          "VPC #{cidr} should estimate #{expected_count} /24 subnets"
      end
    end

    it "provides realistic subnet planning guidance" do
      # Test practical VPC sizes
      vpc_16 = described_class.new(cidr_block: "10.0.0.0/16")
      expect(vpc_16.subnet_count_estimate).to eq(256)
      # This means plenty of room for multi-AZ deployments with public/private tiers
      
      vpc_20 = described_class.new(cidr_block: "10.0.0.0/20") 
      expect(vpc_20.subnet_count_estimate).to eq(16)
      # This means room for 3 AZs × (2 public + 2 private) = 12 subnets with buffer
      
      vpc_24 = described_class.new(cidr_block: "10.0.0.0/24")
      expect(vpc_24.subnet_count_estimate).to eq(1)
      # This means only 1 subnet possible - very constrained
    end
  end

  describe "pure functional properties" do
    it "produces identical results for same input (deterministic)" do
      attrs = { 
        cidr_block: "10.0.0.0/16", 
        tags: { Name: "test", Environment: "dev" } 
      }
      
      vpc1 = described_class.new(attrs)
      vpc2 = described_class.new(attrs)
      
      expect(vpc1.cidr_block).to eq(vpc2.cidr_block)
      expect(vpc1.enable_dns_hostnames).to eq(vpc2.enable_dns_hostnames)
      expect(vpc1.enable_dns_support).to eq(vpc2.enable_dns_support)
      expect(vpc1.instance_tenancy).to eq(vpc2.instance_tenancy)
      expect(vpc1.is_rfc1918_private?).to eq(vpc2.is_rfc1918_private?)
      expect(vpc1.subnet_count_estimate).to eq(vpc2.subnet_count_estimate)
      expect(vpc1.tags).to eq(vpc2.tags)
    end
    
    it "has no side effects during creation" do
      original_attrs = { 
        cidr_block: "10.0.0.0/16", 
        tags: { Name: "test" },
        enable_dns_hostnames: false
      }
      attrs_copy = original_attrs.dup
      
      # Create VPC (should not modify input)
      _vpc = described_class.new(attrs_copy)
      
      # Original attributes should be unchanged (no side effects)
      expect(attrs_copy).to eq(original_attrs)
    end

    it "computed properties are idempotent" do
      vpc_attrs = described_class.new(cidr_block: "172.16.0.0/20")
      
      # Call computed methods multiple times
      5.times do
        expect(vpc_attrs.is_rfc1918_private?).to be true
        expect(vpc_attrs.subnet_count_estimate).to eq(16)
      end
    end

    it "does not leak internal state" do
      vpc_attrs = described_class.new(
        cidr_block: "10.0.0.0/16",
        tags: { Name: "test" }
      )
      
      # Modifying returned tags should not affect the VPC
      returned_tags = vpc_attrs.tags
      returned_tags[:NewKey] = "new_value"
      
      # Original VPC should be unchanged
      fresh_tags = vpc_attrs.tags
      expect(fresh_tags).not_to have_key(:NewKey)
    end
  end

  describe "integration with dry-types system" do
    it "leverages Resources::Types::CidrBlock validation" do
      expect {
        described_class.new(cidr_block: "invalid-cidr")
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it "leverages Resources::Types::InstanceTenancy enum" do
      expect {
        described_class.new(
          cidr_block: "10.0.0.0/16",
          instance_tenancy: "invalid-tenancy"
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it "leverages Resources::Types::Bool for boolean fields" do
      vpc_attrs = described_class.new(
        cidr_block: "10.0.0.0/16",
        enable_dns_hostnames: true,
        enable_dns_support: false
      )
      
      expect(vpc_attrs.enable_dns_hostnames).to be true
      expect(vpc_attrs.enable_dns_support).to be false
    end

    it "leverages Resources::Types::AwsTags for tag validation" do
      vpc_attrs = described_class.new(
        cidr_block: "10.0.0.0/16",
        tags: { Name: "test", Environment: "prod" }
      )
      
      expect(vpc_attrs.tags).to be_a(Hash)
      expect(vpc_attrs.tags.keys).to all(be_a(Symbol))
      expect(vpc_attrs.tags.values).to all(be_a(String))
    end
  end

  describe "error handling and validation messages" do
    it "provides clear error messages for CIDR size violations" do
      expect {
        described_class.new(cidr_block: "10.0.0.0/30")
      }.to raise_error(Dry::Struct::Error) do |error|
        expect(error.message).to include("too small")
        expect(error.message).to include("/28")
      end
      
      expect {
        described_class.new(cidr_block: "10.0.0.0/12") 
      }.to raise_error(Dry::Struct::Error) do |error|
        expect(error.message).to include("too large")
        expect(error.message).to include("/16")
      end
    end

    it "provides helpful guidance in error messages" do
      expect {
        described_class.new(cidr_block: "10.0.0.0/8")
      }.to raise_error(Dry::Struct::Error, /VPCs should typically be \/16 to \/28/)
    end
  end

  describe "real-world usage scenarios" do
    it "supports typical production VPC configuration" do
      production_vpc = described_class.new(
        cidr_block: "10.0.0.0/16",
        enable_dns_hostnames: true,
        enable_dns_support: true,
        instance_tenancy: "default",
        tags: {
          Name: "production-vpc",
          Environment: "production", 
          Team: "platform",
          CostCenter: "engineering",
          Project: "core-infrastructure",
          ManagedBy: "pangea",
          BackupSchedule: "daily",
          ComplianceRequired: "true"
        }
      )
      
      expect(production_vpc.cidr_block).to eq("10.0.0.0/16")
      expect(production_vpc.is_rfc1918_private?).to be true
      expect(production_vpc.subnet_count_estimate).to eq(256)
      expect(production_vpc.tags[:Environment]).to eq("production")
      expect(production_vpc.tags.keys.length).to eq(8)
    end

    it "supports development/testing VPC configuration" do
      dev_vpc = described_class.new(
        cidr_block: "192.168.0.0/20",  # Smaller for dev
        enable_dns_hostnames: true,
        enable_dns_support: true,
        instance_tenancy: "default",
        tags: {
          Name: "development-vpc",
          Environment: "dev",
          Team: "development",
          AutoShutdown: "true",
          TTL: "30-days"
        }
      )
      
      expect(dev_vpc.cidr_block).to eq("192.168.0.0/20")
      expect(dev_vpc.is_rfc1918_private?).to be true
      expect(dev_vpc.subnet_count_estimate).to eq(16)
      expect(dev_vpc.tags[:AutoShutdown]).to eq("true")
    end

    it "supports dedicated tenancy for compliance workloads" do
      compliance_vpc = described_class.new(
        cidr_block: "10.100.0.0/16",
        enable_dns_hostnames: true,
        enable_dns_support: true,
        instance_tenancy: "dedicated",  # For compliance isolation
        tags: {
          Name: "compliance-vpc",
          Environment: "production",
          ComplianceLevel: "SOX",
          DedicatedTenancy: "required",
          DataClassification: "confidential"
        }
      )
      
      expect(compliance_vpc.instance_tenancy).to eq("dedicated")
      expect(compliance_vpc.tags[:ComplianceLevel]).to eq("SOX")
      expect(compliance_vpc.tags[:DedicatedTenancy]).to eq("required")
    end
  end
end