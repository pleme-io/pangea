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
require 'terraform-synthesizer'

# Require the AWS VPC Peering Connection module
require 'pangea/resources/aws_vpc_peering_connection/resource'
require 'pangea/resources/aws_vpc_peering_connection/types'

RSpec.describe "aws_vpc_peering_connection synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }

  # Extend the synthesizer with our VpcPeeringConnection module for resource access
  before do
    synthesizer.extend(Pangea::Resources::VpcPeeringConnection)
  end

  describe "basic peering synthesis" do
    it "synthesizes minimal same-region peering" do
      result = synthesizer.instance_eval do
        aws_vpc_peering_connection(:basic_peering, {
          vpc_id: "vpc-12345678",
          peer_vpc_id: "vpc-87654321",
          auto_accept: true,
          tags: {
            Name: "basic-peering"
          }
        })
        
        synthesis
      end
      
      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_vpc_peering_connection")
      expect(result["resource"]["aws_vpc_peering_connection"]).to have_key("basic_peering")
      
      peering = result["resource"]["aws_vpc_peering_connection"]["basic_peering"]
      expect(peering["vpc_id"]).to eq("vpc-12345678")
      expect(peering["peer_vpc_id"]).to eq("vpc-87654321")
      expect(peering["auto_accept"]).to eq(true)
      expect(peering["tags"]["Name"]).to eq("basic-peering")
    end
    
    it "synthesizes peering without auto-accept" do
      result = synthesizer.instance_eval do
        aws_vpc_peering_connection(:manual_accept, {
          vpc_id: "vpc-12345678",
          peer_vpc_id: "vpc-87654321",
          auto_accept: false
        })
        
        synthesis
      end
      
      peering = result["resource"]["aws_vpc_peering_connection"]["manual_accept"]
      expect(peering["auto_accept"]).to eq(false)
    end
  end
  
  describe "cross-region peering synthesis" do
    it "synthesizes cross-region peering connection" do
      result = synthesizer.instance_eval do
        aws_vpc_peering_connection(:cross_region, {
          vpc_id: "vpc-us-east-12345",
          peer_vpc_id: "vpc-us-west-67890",
          peer_region: "us-west-2",
          tags: {
            Name: "us-east-to-us-west",
            Type: "cross-region"
          }
        })
        
        synthesis
      end
      
      peering = result["resource"]["aws_vpc_peering_connection"]["cross_region"]
      
      expect(peering["vpc_id"]).to eq("vpc-us-east-12345")
      expect(peering["peer_vpc_id"]).to eq("vpc-us-west-67890")
      expect(peering["peer_region"]).to eq("us-west-2")
      expect(peering["auto_accept"]).to eq(false) # Default for cross-region
      expect(peering["tags"]["Type"]).to eq("cross-region")
    end
    
    it "synthesizes multi-region mesh" do
      result = synthesizer.instance_eval do
        # East to West
        aws_vpc_peering_connection(:east_west, {
          vpc_id: "vpc-us-east",
          peer_vpc_id: "vpc-us-west",
          peer_region: "us-west-2"
        })
        
        # East to EU
        aws_vpc_peering_connection(:east_eu, {
          vpc_id: "vpc-us-east",
          peer_vpc_id: "vpc-eu-west",
          peer_region: "eu-west-1"
        })
        
        # West to EU
        aws_vpc_peering_connection(:west_eu, {
          vpc_id: "vpc-us-west",
          peer_vpc_id: "vpc-eu-west",
          peer_region: "eu-west-1"
        })
        
        synthesis
      end
      
      expect(result["resource"]["aws_vpc_peering_connection"]).to have_key("east_west")
      expect(result["resource"]["aws_vpc_peering_connection"]).to have_key("east_eu")
      expect(result["resource"]["aws_vpc_peering_connection"]).to have_key("west_eu")
      
      # Verify cross-region settings
      expect(result["resource"]["aws_vpc_peering_connection"]["east_west"]["peer_region"]).to eq("us-west-2")
      expect(result["resource"]["aws_vpc_peering_connection"]["east_eu"]["peer_region"]).to eq("eu-west-1")
      expect(result["resource"]["aws_vpc_peering_connection"]["west_eu"]["peer_region"]).to eq("eu-west-1")
    end
  end
  
  describe "cross-account peering synthesis" do
    it "synthesizes cross-account peering connection" do
      result = synthesizer.instance_eval do
        aws_vpc_peering_connection(:cross_account, {
          vpc_id: "vpc-12345678",
          peer_vpc_id: "vpc-87654321",
          peer_owner_id: "123456789012",
          tags: {
            Name: "cross-account-peering",
            Security: "partner-integration"
          }
        })
        
        synthesis
      end
      
      peering = result["resource"]["aws_vpc_peering_connection"]["cross_account"]
      
      expect(peering["peer_owner_id"]).to eq("123456789012")
      expect(peering["auto_accept"]).to eq(false) # Must be false for cross-account
    end
    
    it "synthesizes cross-region cross-account peering" do
      result = synthesizer.instance_eval do
        aws_vpc_peering_connection(:cross_both, {
          vpc_id: "vpc-internal",
          peer_vpc_id: "vpc-partner",
          peer_owner_id: "987654321098",
          peer_region: "eu-central-1",
          tags: {
            Name: "partner-eu-peering",
            Type: "cross-region-cross-account"
          }
        })
        
        synthesis
      end
      
      peering = result["resource"]["aws_vpc_peering_connection"]["cross_both"]
      
      expect(peering["peer_owner_id"]).to eq("987654321098")
      expect(peering["peer_region"]).to eq("eu-central-1")
      expect(peering["auto_accept"]).to eq(false)
    end
  end
  
  describe "DNS resolution synthesis" do
    it "synthesizes peering with DNS resolution enabled" do
      result = synthesizer.instance_eval do
        aws_vpc_peering_connection(:with_dns, {
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
        
        synthesis
      end
      
      peering = result["resource"]["aws_vpc_peering_connection"]["with_dns"]
      
      expect(peering["requester"]).to be_a(Hash)
      expect(peering["requester"]["allow_remote_vpc_dns_resolution"]).to eq(true)
      expect(peering["accepter"]).to be_a(Hash)
      expect(peering["accepter"]["allow_remote_vpc_dns_resolution"]).to eq(true)
    end
    
    it "synthesizes asymmetric DNS resolution" do
      result = synthesizer.instance_eval do
        aws_vpc_peering_connection(:asymmetric_dns, {
          vpc_id: "vpc-12345678",
          peer_vpc_id: "vpc-87654321",
          auto_accept: true,
          requester: {
            allow_remote_vpc_dns_resolution: true
          },
          accepter: {
            allow_remote_vpc_dns_resolution: false
          }
        })
        
        synthesis
      end
      
      peering = result["resource"]["aws_vpc_peering_connection"]["asymmetric_dns"]
      
      expect(peering["requester"]["allow_remote_vpc_dns_resolution"]).to eq(true)
      expect(peering["accepter"]["allow_remote_vpc_dns_resolution"]).to eq(false)
    end
  end
  
  describe "real-world patterns synthesis" do
    it "synthesizes hub-spoke architecture" do
      result = synthesizer.instance_eval do
        # Hub to Spoke 1
        aws_vpc_peering_connection(:hub_spoke1, {
          vpc_id: "vpc-hub-central",
          peer_vpc_id: "vpc-spoke1-dev",
          auto_accept: true,
          requester: { allow_remote_vpc_dns_resolution: true },
          accepter: { allow_remote_vpc_dns_resolution: true },
          tags: {
            Name: "hub-to-spoke1",
            Pattern: "hub-spoke",
            Hub: "central",
            Spoke: "dev"
          }
        })
        
        # Hub to Spoke 2
        aws_vpc_peering_connection(:hub_spoke2, {
          vpc_id: "vpc-hub-central",
          peer_vpc_id: "vpc-spoke2-prod",
          auto_accept: true,
          requester: { allow_remote_vpc_dns_resolution: true },
          accepter: { allow_remote_vpc_dns_resolution: true },
          tags: {
            Name: "hub-to-spoke2",
            Pattern: "hub-spoke",
            Hub: "central",
            Spoke: "prod"
          }
        })
        
        # Hub to Spoke 3
        aws_vpc_peering_connection(:hub_spoke3, {
          vpc_id: "vpc-hub-central",
          peer_vpc_id: "vpc-spoke3-staging",
          auto_accept: true,
          requester: { allow_remote_vpc_dns_resolution: true },
          accepter: { allow_remote_vpc_dns_resolution: true },
          tags: {
            Name: "hub-to-spoke3",
            Pattern: "hub-spoke",
            Hub: "central",
            Spoke: "staging"
          }
        })
        
        synthesis
      end
      
      # Verify all hub connections exist
      expect(result["resource"]["aws_vpc_peering_connection"]).to have_key("hub_spoke1")
      expect(result["resource"]["aws_vpc_peering_connection"]).to have_key("hub_spoke2")
      expect(result["resource"]["aws_vpc_peering_connection"]).to have_key("hub_spoke3")
      
      # All connections should have DNS resolution enabled
      ["hub_spoke1", "hub_spoke2", "hub_spoke3"].each do |conn|
        peering = result["resource"]["aws_vpc_peering_connection"][conn]
        expect(peering["requester"]["allow_remote_vpc_dns_resolution"]).to eq(true)
        expect(peering["accepter"]["allow_remote_vpc_dns_resolution"]).to eq(true)
        expect(peering["tags"]["Pattern"]).to eq("hub-spoke")
      end
    end
    
    it "synthesizes environment isolation pattern" do
      result = synthesizer.instance_eval do
        # Development to Staging
        aws_vpc_peering_connection(:dev_staging, {
          vpc_id: "vpc-dev",
          peer_vpc_id: "vpc-staging",
          auto_accept: true,
          tags: {
            Name: "dev-to-staging",
            SourceEnv: "development",
            TargetEnv: "staging",
            Purpose: "testing-promotion"
          }
        })
        
        # Staging to Production (cross-account for security)
        aws_vpc_peering_connection(:staging_prod, {
          vpc_id: "vpc-staging",
          peer_vpc_id: "vpc-prod",
          peer_owner_id: "987654321098",
          tags: {
            Name: "staging-to-prod",
            SourceEnv: "staging",
            TargetEnv: "production",
            Security: "cross-account-boundary",
            Approval: "required"
          }
        })
        
        synthesis
      end
      
      dev_staging = result["resource"]["aws_vpc_peering_connection"]["dev_staging"]
      staging_prod = result["resource"]["aws_vpc_peering_connection"]["staging_prod"]
      
      # Dev to staging can auto-accept
      expect(dev_staging["auto_accept"]).to eq(true)
      
      # Staging to prod requires manual acceptance
      expect(staging_prod["peer_owner_id"]).to eq("987654321098")
      expect(staging_prod["auto_accept"]).to eq(false)
    end
    
    it "synthesizes disaster recovery pattern" do
      result = synthesizer.instance_eval do
        # Primary to DR region
        aws_vpc_peering_connection(:primary_dr, {
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
            RTO: "1-hour",
            Criticality: "high",
            DataReplication: "active"
          }
        })
        
        synthesis
      end
      
      dr_peering = result["resource"]["aws_vpc_peering_connection"]["primary_dr"]
      
      expect(dr_peering["peer_region"]).to eq("us-west-2")
      expect(dr_peering["tags"]["Purpose"]).to eq("disaster-recovery")
      expect(dr_peering["tags"]["Criticality"]).to eq("high")
    end
    
    it "synthesizes shared services pattern" do
      result = synthesizer.instance_eval do
        # App VPC to Shared Services
        aws_vpc_peering_connection(:app_shared, {
          vpc_id: "vpc-app-workload",
          peer_vpc_id: "vpc-shared-services",
          auto_accept: true,
          requester: { allow_remote_vpc_dns_resolution: true },
          accepter: { allow_remote_vpc_dns_resolution: true },
          tags: {
            Name: "app-to-shared-services",
            Pattern: "shared-services",
            Services: "logging,monitoring,backup"
          }
        })
        
        # Database VPC to Shared Services
        aws_vpc_peering_connection(:db_shared, {
          vpc_id: "vpc-database",
          peer_vpc_id: "vpc-shared-services",
          auto_accept: true,
          requester: { allow_remote_vpc_dns_resolution: true },
          accepter: { allow_remote_vpc_dns_resolution: true },
          tags: {
            Name: "db-to-shared-services",
            Pattern: "shared-services",
            Services: "backup,monitoring"
          }
        })
        
        synthesis
      end
      
      # Both connections should have DNS enabled for service discovery
      app_shared = result["resource"]["aws_vpc_peering_connection"]["app_shared"]
      db_shared = result["resource"]["aws_vpc_peering_connection"]["db_shared"]
      
      expect(app_shared["requester"]["allow_remote_vpc_dns_resolution"]).to eq(true)
      expect(db_shared["requester"]["allow_remote_vpc_dns_resolution"]).to eq(true)
    end
    
    it "synthesizes partner integration pattern" do
      result = synthesizer.instance_eval do
        aws_vpc_peering_connection(:partner_api, {
          vpc_id: "vpc-internal-api",
          peer_vpc_id: "vpc-partner-integration",
          peer_owner_id: "555666777888",
          peer_region: "us-east-1",
          tags: {
            Name: "internal-to-partner-api",
            Integration: "partner-b2b",
            Partner: "acme-corp",
            DataClassification: "confidential",
            Compliance: "soc2,pci",
            SecurityReview: "approved-2023-11",
            ExpirationDate: "2024-12-31"
          }
        })
        
        synthesis
      end
      
      partner = result["resource"]["aws_vpc_peering_connection"]["partner_api"]
      
      expect(partner["peer_owner_id"]).to eq("555666777888")
      expect(partner["tags"]["Compliance"]).to eq("soc2,pci")
      expect(partner["tags"]["ExpirationDate"]).to eq("2024-12-31")
    end
  end
  
  describe "tag synthesis" do
    it "synthesizes comprehensive tags" do
      result = synthesizer.instance_eval do
        aws_vpc_peering_connection(:tagged_peering, {
          vpc_id: "vpc-12345678",
          peer_vpc_id: "vpc-87654321",
          auto_accept: true,
          tags: {
            Name: "production-peering-connection",
            Environment: "production",
            Application: "core-infrastructure",
            Team: "networking",
            CostCenter: "engineering",
            Project: "vpc-consolidation",
            ManagedBy: "terraform",
            CreatedDate: "2023-11-20",
            ReviewDate: "2024-05-20"
          }
        })
        
        synthesis
      end
      
      tags = result["resource"]["aws_vpc_peering_connection"]["tagged_peering"]["tags"]
      expect(tags).to include(
        Name: "production-peering-connection",
        Environment: "production",
        Application: "core-infrastructure",
        Team: "networking"
      )
    end
  end
end