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

# Load aws_vpc_peering_connection resource and types for testing
require 'pangea/resources/aws_vpc_peering_connection/resource'
require 'pangea/resources/aws_vpc_peering_connection/types'

RSpec.describe "aws_vpc_peering_connection resource function" do
  # Create a test class that includes the VpcPeeringConnection module and mocks terraform-synthesizer
  let(:test_class) do
    Class.new do
      include Pangea::Resources::VpcPeeringConnection
      
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
  
  describe "VpcPeeringConnectionAttributes validation" do
    it "accepts same-region peering configuration" do
      peering = Pangea::Resources::VpcPeeringConnectionAttributes.new({
        vpc_id: "vpc-12345678",
        peer_vpc_id: "vpc-87654321",
        auto_accept: true,
        tags: {
          Name: "dev-to-prod-peering",
          Environment: "production"
        }
      })
      
      expect(peering.vpc_id).to eq("vpc-12345678")
      expect(peering.peer_vpc_id).to eq("vpc-87654321")
      expect(peering.auto_accept).to eq(true)
      expect(peering.is_cross_region?).to eq(false)
      expect(peering.is_cross_account?).to eq(false)
    end
    
    it "accepts cross-region peering configuration" do
      peering = Pangea::Resources::VpcPeeringConnectionAttributes.new({
        vpc_id: "vpc-12345678",
        peer_vpc_id: "vpc-87654321",
        peer_region: "us-west-2",
        auto_accept: false,
        tags: {
          Name: "us-east-1-to-us-west-2",
          Type: "cross-region"
        }
      })
      
      expect(peering.peer_region).to eq("us-west-2")
      expect(peering.auto_accept).to eq(false)
      expect(peering.is_cross_region?).to eq(true)
      expect(peering.is_cross_account?).to eq(false)
    end
    
    it "accepts cross-account peering configuration" do
      peering = Pangea::Resources::VpcPeeringConnectionAttributes.new({
        vpc_id: "vpc-12345678",
        peer_vpc_id: "vpc-87654321",
        peer_owner_id: "123456789012",
        auto_accept: false,
        tags: {
          Name: "cross-account-peering",
          Type: "cross-account"
        }
      })
      
      expect(peering.peer_owner_id).to eq("123456789012")
      expect(peering.is_cross_account?).to eq(true)
      expect(peering.is_cross_region?).to eq(false)
    end
    
    it "accepts cross-account and cross-region peering" do
      peering = Pangea::Resources::VpcPeeringConnectionAttributes.new({
        vpc_id: "vpc-12345678",
        peer_vpc_id: "vpc-87654321",
        peer_owner_id: "123456789012",
        peer_region: "eu-west-1",
        auto_accept: false
      })
      
      expect(peering.is_cross_account?).to eq(true)
      expect(peering.is_cross_region?).to eq(true)
    end
    
    it "validates auto_accept cannot be true for cross-account peering" do
      expect {
        Pangea::Resources::VpcPeeringConnectionAttributes.new({
          vpc_id: "vpc-12345678",
          peer_vpc_id: "vpc-87654321",
          peer_owner_id: "123456789012",
          auto_accept: true
        })
      }.to raise_error(Dry::Struct::Error, /auto_accept cannot be true for cross-account peering connections/)
    end
    
    it "accepts requester options" do
      peering = Pangea::Resources::VpcPeeringConnectionAttributes.new({
        vpc_id: "vpc-12345678",
        peer_vpc_id: "vpc-87654321",
        requester: {
          allow_remote_vpc_dns_resolution: true
        }
      })
      
      expect(peering.requester[:allow_remote_vpc_dns_resolution]).to eq(true)
    end
    
    it "accepts accepter options" do
      peering = Pangea::Resources::VpcPeeringConnectionAttributes.new({
        vpc_id: "vpc-12345678",
        peer_vpc_id: "vpc-87654321",
        accepter: {
          allow_remote_vpc_dns_resolution: true
        }
      })
      
      expect(peering.accepter[:allow_remote_vpc_dns_resolution]).to eq(true)
    end
    
    it "provides peering type identification" do
      # Same region/account
      same_region = Pangea::Resources::VpcPeeringConnectionAttributes.new({
        vpc_id: "vpc-12345678",
        peer_vpc_id: "vpc-87654321"
      })
      expect(same_region.peering_type).to eq("same-region-same-account")
      
      # Cross region
      cross_region = Pangea::Resources::VpcPeeringConnectionAttributes.new({
        vpc_id: "vpc-12345678",
        peer_vpc_id: "vpc-87654321",
        peer_region: "us-west-2"
      })
      expect(cross_region.peering_type).to eq("cross-region-same-account")
      
      # Cross account
      cross_account = Pangea::Resources::VpcPeeringConnectionAttributes.new({
        vpc_id: "vpc-12345678",
        peer_vpc_id: "vpc-87654321",
        peer_owner_id: "123456789012"
      })
      expect(cross_account.peering_type).to eq("same-region-cross-account")
      
      # Cross region and account
      cross_both = Pangea::Resources::VpcPeeringConnectionAttributes.new({
        vpc_id: "vpc-12345678",
        peer_vpc_id: "vpc-87654321",
        peer_region: "eu-west-1",
        peer_owner_id: "123456789012"
      })
      expect(cross_both.peering_type).to eq("cross-region-cross-account")
    end
    
    it "provides configuration warnings" do
      # DNS resolution without auto_accept
      peering = Pangea::Resources::VpcPeeringConnectionAttributes.new({
        vpc_id: "vpc-12345678",
        peer_vpc_id: "vpc-87654321",
        auto_accept: false,
        requester: {
          allow_remote_vpc_dns_resolution: true
        }
      })
      warnings = peering.validate_configuration
      expect(warnings).to include("DNS resolution is configured but auto_accept is false - accepter must manually configure DNS resolution")
      
      # Cross-account without owner ID
      cross_account = Pangea::Resources::VpcPeeringConnectionAttributes.new({
        vpc_id: "vpc-12345678",
        peer_vpc_id: "vpc-87654321",
        peer_owner_id: "123456789012"
      })
      warnings = cross_account.validate_configuration
      expect(warnings).to include("Cross-account peering requires manual acceptance in peer account")
    end
  end
  
  describe "VpcPeeringConfigs module" do
    it "creates same-region peering configuration" do
      config = Pangea::Resources::VpcPeeringConfigs.same_region_peering(
        "vpc-12345678",
        "vpc-87654321",
        auto_accept: true,
        enable_dns: true
      )
      
      expect(config[:vpc_id]).to eq("vpc-12345678")
      expect(config[:peer_vpc_id]).to eq("vpc-87654321")
      expect(config[:auto_accept]).to eq(true)
      expect(config[:requester][:allow_remote_vpc_dns_resolution]).to eq(true)
      expect(config[:accepter][:allow_remote_vpc_dns_resolution]).to eq(true)
    end
    
    it "creates cross-region peering configuration" do
      config = Pangea::Resources::VpcPeeringConfigs.cross_region_peering(
        "vpc-12345678",
        "vpc-87654321",
        "us-west-2",
        enable_dns: false
      )
      
      expect(config[:vpc_id]).to eq("vpc-12345678")
      expect(config[:peer_vpc_id]).to eq("vpc-87654321")
      expect(config[:peer_region]).to eq("us-west-2")
      expect(config[:auto_accept]).to eq(false)
      expect(config[:requester]).to be_empty
    end
    
    it "creates cross-account peering configuration" do
      config = Pangea::Resources::VpcPeeringConfigs.cross_account_peering(
        "vpc-12345678",
        "vpc-87654321",
        "123456789012",
        region: "us-east-1"
      )
      
      expect(config[:vpc_id]).to eq("vpc-12345678")
      expect(config[:peer_vpc_id]).to eq("vpc-87654321")
      expect(config[:peer_owner_id]).to eq("123456789012")
      expect(config[:peer_region]).to eq("us-east-1")
      expect(config[:auto_accept]).to eq(false)
    end
    
    it "creates hub-spoke peering configuration" do
      config = Pangea::Resources::VpcPeeringConfigs.hub_spoke_peering(
        "vpc-hub-12345",
        "vpc-spoke-67890",
        spoke_name: "dev-spoke"
      )
      
      expect(config[:vpc_id]).to eq("vpc-hub-12345")
      expect(config[:peer_vpc_id]).to eq("vpc-spoke-67890")
      expect(config[:auto_accept]).to eq(true)
      expect(config[:tags][:Pattern]).to eq("hub-spoke")
      expect(config[:tags][:Name]).to eq("hub-to-dev-spoke")
    end
    
    it "creates transit peering configuration" do
      config = Pangea::Resources::VpcPeeringConfigs.transit_peering(
        "vpc-12345678",
        "vpc-transit",
        enable_dns: true
      )
      
      expect(config[:peer_vpc_id]).to eq("vpc-transit")
      expect(config[:auto_accept]).to eq(true)
      expect(config[:requester][:allow_remote_vpc_dns_resolution]).to eq(true)
      expect(config[:tags][:Purpose]).to eq("transit-connectivity")
    end
  end
  
  describe "aws_vpc_peering_connection function" do
    it "creates basic same-region peering connection" do
      result = test_instance.aws_vpc_peering_connection(:dev_to_prod, {
        vpc_id: "vpc-dev-12345",
        peer_vpc_id: "vpc-prod-67890",
        auto_accept: true,
        tags: {
          Name: "dev-to-prod-peering",
          Environment: "production"
        }
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_vpc_peering_connection')
      expect(result.name).to eq(:dev_to_prod)
      expect(result.id).to eq("${aws_vpc_peering_connection.dev_to_prod.id}")
    end
    
    it "creates cross-region peering connection" do
      result = test_instance.aws_vpc_peering_connection(:east_to_west, {
        vpc_id: "vpc-east-12345",
        peer_vpc_id: "vpc-west-67890",
        peer_region: "us-west-2",
        requester: {
          allow_remote_vpc_dns_resolution: true
        }
      })
      
      expect(result.resource_attributes[:peer_region]).to eq("us-west-2")
      expect(result.resource_attributes[:auto_accept]).to eq(false)
      expect(result.is_cross_region?).to eq(true)
    end
    
    it "creates cross-account peering connection" do
      result = test_instance.aws_vpc_peering_connection(:cross_account, {
        vpc_id: "vpc-12345678",
        peer_vpc_id: "vpc-87654321",
        peer_owner_id: "123456789012",
        tags: {
          Name: "cross-account-peering",
          Owner: "partner-account"
        }
      })
      
      expect(result.resource_attributes[:peer_owner_id]).to eq("123456789012")
      expect(result.is_cross_account?).to eq(true)
      expect(result.resource_attributes[:auto_accept]).to eq(false)
    end
    
    it "creates peering with DNS resolution options" do
      result = test_instance.aws_vpc_peering_connection(:with_dns, {
        vpc_id: "vpc-12345678",
        peer_vpc_id: "vpc-87654321",
        auto_accept: true,
        requester: {
          allow_remote_vpc_dns_resolution: true
        },
        accepter: {
          allow_remote_vpc_dns_resolution: true
        }
      })
      
      expect(result.resource_attributes[:requester][:allow_remote_vpc_dns_resolution]).to eq(true)
      expect(result.resource_attributes[:accepter][:allow_remote_vpc_dns_resolution]).to eq(true)
    end
    
    it "provides correct outputs" do
      result = test_instance.aws_vpc_peering_connection(:test, {
        vpc_id: "vpc-12345678",
        peer_vpc_id: "vpc-87654321"
      })
      
      expect(result.id).to eq("${aws_vpc_peering_connection.test.id}")
      expect(result.accept_status).to eq("${aws_vpc_peering_connection.test.accept_status}")
      expect(result.vpc_id).to eq("${aws_vpc_peering_connection.test.vpc_id}")
      expect(result.peer_vpc_id).to eq("${aws_vpc_peering_connection.test.peer_vpc_id}")
      expect(result.peer_owner_id).to eq("${aws_vpc_peering_connection.test.peer_owner_id}")
      expect(result.peer_region).to eq("${aws_vpc_peering_connection.test.peer_region}")
    end
    
    it "provides computed properties" do
      result = test_instance.aws_vpc_peering_connection(:computed_test, {
        vpc_id: "vpc-12345678",
        peer_vpc_id: "vpc-87654321",
        peer_region: "us-west-2",
        peer_owner_id: "123456789012"
      })
      
      expect(result.is_cross_region?).to eq(true)
      expect(result.is_cross_account?).to eq(true)
      expect(result.peering_type).to eq("cross-region-cross-account")
      expect(result.requires_manual_acceptance?).to eq(true)
      expect(result.supports_dns_resolution?).to eq(false)
    end
  end
  
  describe "peering patterns" do
    it "creates hub-spoke architecture peering" do
      # Hub VPC to multiple spoke VPCs
      spoke1 = test_instance.aws_vpc_peering_connection(:hub_to_spoke1, {
        vpc_id: "vpc-hub-central",
        peer_vpc_id: "vpc-spoke1-dev",
        auto_accept: true,
        requester: { allow_remote_vpc_dns_resolution: true },
        accepter: { allow_remote_vpc_dns_resolution: true },
        tags: {
          Name: "hub-to-spoke1-dev",
          Pattern: "hub-spoke",
          Role: "hub-connection"
        }
      })
      
      spoke2 = test_instance.aws_vpc_peering_connection(:hub_to_spoke2, {
        vpc_id: "vpc-hub-central",
        peer_vpc_id: "vpc-spoke2-prod",
        auto_accept: true,
        requester: { allow_remote_vpc_dns_resolution: true },
        accepter: { allow_remote_vpc_dns_resolution: true },
        tags: {
          Name: "hub-to-spoke2-prod",
          Pattern: "hub-spoke",
          Role: "hub-connection"
        }
      })
      
      expect(spoke1.resource_attributes[:tags][:Pattern]).to eq("hub-spoke")
      expect(spoke2.resource_attributes[:tags][:Pattern]).to eq("hub-spoke")
    end
    
    it "creates multi-region mesh peering" do
      # US-East to US-West
      east_west = test_instance.aws_vpc_peering_connection(:east_to_west, {
        vpc_id: "vpc-us-east-1",
        peer_vpc_id: "vpc-us-west-2",
        peer_region: "us-west-2",
        requester: { allow_remote_vpc_dns_resolution: true },
        tags: {
          Name: "us-east-to-us-west",
          Pattern: "multi-region-mesh"
        }
      })
      
      # US-East to EU-West
      east_eu = test_instance.aws_vpc_peering_connection(:east_to_eu, {
        vpc_id: "vpc-us-east-1",
        peer_vpc_id: "vpc-eu-west-1",
        peer_region: "eu-west-1",
        requester: { allow_remote_vpc_dns_resolution: true },
        tags: {
          Name: "us-east-to-eu-west",
          Pattern: "multi-region-mesh"
        }
      })
      
      expect(east_west.is_cross_region?).to eq(true)
      expect(east_eu.is_cross_region?).to eq(true)
      expect(east_west.resource_attributes[:peer_region]).to eq("us-west-2")
      expect(east_eu.resource_attributes[:peer_region]).to eq("eu-west-1")
    end
    
    it "creates environment isolation peering" do
      # Dev to staging (same account)
      dev_staging = test_instance.aws_vpc_peering_connection(:dev_to_staging, {
        vpc_id: "vpc-dev-12345",
        peer_vpc_id: "vpc-staging-67890",
        auto_accept: true,
        tags: {
          Name: "dev-to-staging",
          Purpose: "environment-connectivity",
          SourceEnv: "development",
          TargetEnv: "staging"
        }
      })
      
      # Staging to production (cross-account for security)
      staging_prod = test_instance.aws_vpc_peering_connection(:staging_to_prod, {
        vpc_id: "vpc-staging-67890",
        peer_vpc_id: "vpc-prod-11111",
        peer_owner_id: "987654321098",
        tags: {
          Name: "staging-to-prod",
          Purpose: "environment-connectivity",
          SourceEnv: "staging",
          TargetEnv: "production",
          Security: "cross-account-isolation"
        }
      })
      
      expect(dev_staging.resource_attributes[:auto_accept]).to eq(true)
      expect(staging_prod.is_cross_account?).to eq(true)
      expect(staging_prod.requires_manual_acceptance?).to eq(true)
    end
    
    it "creates shared services peering" do
      # Application VPCs to shared services VPC
      app_to_shared = test_instance.aws_vpc_peering_connection(:app_to_shared, {
        vpc_id: "vpc-app-12345",
        peer_vpc_id: "vpc-shared-services",
        auto_accept: true,
        requester: { allow_remote_vpc_dns_resolution: true },
        accepter: { allow_remote_vpc_dns_resolution: true },
        tags: {
          Name: "app-to-shared-services",
          Pattern: "shared-services",
          Purpose: "centralized-services"
        }
      })
      
      expect(app_to_shared.resource_attributes[:requester][:allow_remote_vpc_dns_resolution]).to eq(true)
      expect(app_to_shared.resource_attributes[:accepter][:allow_remote_vpc_dns_resolution]).to eq(true)
    end
  end
  
  describe "advanced configurations" do
    it "creates disaster recovery peering" do
      result = test_instance.aws_vpc_peering_connection(:dr_peering, {
        vpc_id: "vpc-primary-us-east",
        peer_vpc_id: "vpc-dr-us-west",
        peer_region: "us-west-2",
        requester: {
          allow_remote_vpc_dns_resolution: true
        },
        tags: {
          Name: "primary-to-dr",
          Purpose: "disaster-recovery",
          RPO: "15-minutes",
          Criticality: "high"
        }
      })
      
      expect(result.is_cross_region?).to eq(true)
      expect(result.resource_attributes[:tags][:Purpose]).to eq("disaster-recovery")
    end
    
    it "creates partner integration peering" do
      result = test_instance.aws_vpc_peering_connection(:partner_integration, {
        vpc_id: "vpc-internal-12345",
        peer_vpc_id: "vpc-partner-67890",
        peer_owner_id: "111222333444",
        peer_region: "us-east-1",
        tags: {
          Name: "internal-to-partner",
          Integration: "partner-api",
          Partner: "acme-corp",
          Security: "restricted",
          Compliance: "pci-dss"
        }
      })
      
      expect(result.is_cross_account?).to eq(true)
      expect(result.resource_attributes[:tags][:Security]).to eq("restricted")
    end
  end
  
  describe "error conditions" do
    it "handles missing required attributes" do
      expect {
        test_instance.aws_vpc_peering_connection(:invalid, {
          vpc_id: "vpc-12345678"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "handles auto_accept with cross-account peering" do
      expect {
        test_instance.aws_vpc_peering_connection(:invalid_auto_accept, {
          vpc_id: "vpc-12345678",
          peer_vpc_id: "vpc-87654321",
          peer_owner_id: "123456789012",
          auto_accept: true
        })
      }.to raise_error(Dry::Struct::Error, /auto_accept cannot be true/)
    end
  end
end