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

# Require the AWS EFS File System module
require 'pangea/resources/aws_efs_file_system/resource'
require 'pangea/resources/aws_efs_file_system/types'

RSpec.describe "aws_efs_file_system synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }

  # Extend the synthesizer with our AWS module for resource access
  before do
    synthesizer.extend(Pangea::Resources::AWS)
  end

  describe "basic EFS synthesis" do
    it "synthesizes minimal EFS file system" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:basic_efs, {
          creation_token: "my-efs-token",
          tags: {
            Name: "basic-efs"
          }
        })
        
        synthesis
      end
      
      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_efs_file_system")
      expect(result["resource"]["aws_efs_file_system"]).to have_key("basic_efs")
      
      efs = result["resource"]["aws_efs_file_system"]["basic_efs"]
      expect(efs["creation_token"]).to eq("my-efs-token")
      expect(efs["tags"]["Name"]).to eq("basic-efs")
      
      # Defaults
      expect(efs["performance_mode"]).to eq("generalPurpose")
      expect(efs["throughput_mode"]).to eq("bursting")
      expect(efs["encrypted"]).to eq(false)
    end
    
    it "synthesizes encrypted EFS" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:encrypted_efs, {
          creation_token: "encrypted-efs-token",
          encrypted: true,
          kms_key_id: "alias/aws/efs"
        })
        
        synthesis
      end
      
      efs = result["resource"]["aws_efs_file_system"]["encrypted_efs"]
      expect(efs["encrypted"]).to eq(true)
      expect(efs["kms_key_id"]).to eq("alias/aws/efs")
    end
  end
  
  describe "performance configuration synthesis" do
    it "synthesizes general purpose EFS" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:general_purpose, {
          creation_token: "gp-efs",
          performance_mode: "generalPurpose",
          throughput_mode: "bursting"
        })
        
        synthesis
      end
      
      efs = result["resource"]["aws_efs_file_system"]["general_purpose"]
      expect(efs["performance_mode"]).to eq("generalPurpose")
      expect(efs["throughput_mode"]).to eq("bursting")
    end
    
    it "synthesizes max I/O EFS" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:max_io, {
          creation_token: "maxio-efs",
          performance_mode: "maxIO",
          throughput_mode: "bursting"
        })
        
        synthesis
      end
      
      efs = result["resource"]["aws_efs_file_system"]["max_io"]
      expect(efs["performance_mode"]).to eq("maxIO")
    end
    
    it "synthesizes provisioned throughput EFS" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:provisioned, {
          creation_token: "provisioned-efs",
          performance_mode: "generalPurpose",
          throughput_mode: "provisioned",
          provisioned_throughput_in_mibps: 100
        })
        
        synthesis
      end
      
      efs = result["resource"]["aws_efs_file_system"]["provisioned"]
      expect(efs["throughput_mode"]).to eq("provisioned")
      expect(efs["provisioned_throughput_in_mibps"]).to eq(100)
    end
    
    it "synthesizes elastic throughput EFS" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:elastic, {
          creation_token: "elastic-efs",
          throughput_mode: "elastic",
          encrypted: true
        })
        
        synthesis
      end
      
      efs = result["resource"]["aws_efs_file_system"]["elastic"]
      expect(efs["throughput_mode"]).to eq("elastic")
    end
  end
  
  describe "storage class synthesis" do
    it "synthesizes regional (multi-AZ) EFS" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:regional, {
          creation_token: "regional-efs",
          encrypted: true
        })
        
        synthesis
      end
      
      efs = result["resource"]["aws_efs_file_system"]["regional"]
      expect(efs).not_to have_key("availability_zone_name")
      expect(efs["creation_token"]).to eq("regional-efs")
    end
    
    it "synthesizes One Zone EFS" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:one_zone, {
          creation_token: "onezone-efs",
          availability_zone_name: "us-east-1a",
          encrypted: true
        })
        
        synthesis
      end
      
      efs = result["resource"]["aws_efs_file_system"]["one_zone"]
      expect(efs["availability_zone_name"]).to eq("us-east-1a")
      expect(efs["performance_mode"]).to eq("generalPurpose") # maxIO not allowed for One Zone
    end
  end
  
  describe "lifecycle policy synthesis" do
    it "synthesizes EFS with simple IA transition" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:ia_lifecycle, {
          creation_token: "ia-lifecycle-efs",
          lifecycle_policy: [{
            transition_to_ia: "AFTER_30_DAYS"
          }]
        })
        
        synthesis
      end
      
      efs = result["resource"]["aws_efs_file_system"]["ia_lifecycle"]
      expect(efs["lifecycle_policy"]).to be_an(Array)
      expect(efs["lifecycle_policy"]).to have(1).item
      expect(efs["lifecycle_policy"].first).to eq({ "transition_to_ia" => "AFTER_30_DAYS" })
    end
    
    it "synthesizes EFS with multiple lifecycle transitions" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:full_lifecycle, {
          creation_token: "full-lifecycle-efs",
          lifecycle_policy: [
            { transition_to_ia: "AFTER_7_DAYS" },
            { transition_to_archive: "AFTER_90_DAYS" }
          ]
        })
        
        synthesis
      end
      
      efs = result["resource"]["aws_efs_file_system"]["full_lifecycle"]
      expect(efs["lifecycle_policy"]).to have(2).items
      expect(efs["lifecycle_policy"][0]["transition_to_ia"]).to eq("AFTER_7_DAYS")
      expect(efs["lifecycle_policy"][1]["transition_to_archive"]).to eq("AFTER_90_DAYS")
    end
  end
  
  describe "backup policy synthesis" do
    it "synthesizes EFS with backup enabled" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:backup_enabled, {
          creation_token: "backup-efs",
          backup_policy: {
            status: "ENABLED"
          }
        })
        
        synthesis
      end
      
      efs = result["resource"]["aws_efs_file_system"]["backup_enabled"]
      expect(efs["backup_policy"]).to be_a(Hash)
      expect(efs["backup_policy"]["status"]).to eq("ENABLED")
    end
    
    it "synthesizes EFS with backup disabled" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:backup_disabled, {
          creation_token: "no-backup-efs",
          backup_policy: {
            status: "DISABLED"
          }
        })
        
        synthesis
      end
      
      efs = result["resource"]["aws_efs_file_system"]["backup_disabled"]
      expect(efs["backup_policy"]["status"]).to eq("DISABLED")
    end
  end
  
  describe "real-world patterns synthesis" do
    it "synthesizes high-performance HPC storage" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:hpc_storage, {
          creation_token: "hpc-shared-storage",
          performance_mode: "maxIO",
          throughput_mode: "provisioned",
          provisioned_throughput_in_mibps: 1024,
          encrypted: true,
          kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
          tags: {
            Name: "hpc-parallel-filesystem",
            Workload: "high-performance-computing",
            Throughput: "1024-mibps",
            CostCenter: "research"
          }
        })
        
        synthesis
      end
      
      efs = result["resource"]["aws_efs_file_system"]["hpc_storage"]
      expect(efs["performance_mode"]).to eq("maxIO")
      expect(efs["throughput_mode"]).to eq("provisioned")
      expect(efs["provisioned_throughput_in_mibps"]).to eq(1024)
      expect(efs["encrypted"]).to eq(true)
    end
    
    it "synthesizes cost-optimized storage with lifecycle" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:cost_optimized, {
          creation_token: "cost-opt-storage",
          availability_zone_name: "us-east-1a",
          lifecycle_policy: [
            { transition_to_ia: "AFTER_1_DAY" },
            { transition_to_archive: "AFTER_14_DAYS" }
          ],
          encrypted: true,
          tags: {
            Name: "cost-optimized-efs",
            StorageClass: "one-zone",
            LifecyclePolicy: "aggressive",
            CostOptimization: "enabled"
          }
        })
        
        synthesis
      end
      
      efs = result["resource"]["aws_efs_file_system"]["cost_optimized"]
      expect(efs["availability_zone_name"]).to eq("us-east-1a")
      expect(efs["lifecycle_policy"]).to have(2).items
      expect(efs["lifecycle_policy"][0]["transition_to_ia"]).to eq("AFTER_1_DAY")
    end
    
    it "synthesizes container orchestration storage" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:k8s_storage, {
          creation_token: "eks-persistent-storage",
          performance_mode: "generalPurpose",
          throughput_mode: "elastic",
          encrypted: true,
          lifecycle_policy: [{
            transition_to_ia: "AFTER_30_DAYS"
          }],
          backup_policy: {
            status: "ENABLED"
          },
          tags: {
            Name: "eks-shared-storage",
            "kubernetes.io/cluster/prod-eks": "owned",
            StorageClass: "efs-sc",
            Orchestrator: "kubernetes"
          }
        })
        
        synthesis
      end
      
      efs = result["resource"]["aws_efs_file_system"]["k8s_storage"]
      expect(efs["throughput_mode"]).to eq("elastic")
      expect(efs["backup_policy"]["status"]).to eq("ENABLED")
      expect(efs["tags"]["kubernetes.io/cluster/prod-eks"]).to eq("owned")
    end
    
    it "synthesizes ML/AI training storage" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:ml_training, {
          creation_token: "ml-training-storage",
          performance_mode: "maxIO",
          throughput_mode: "provisioned",
          provisioned_throughput_in_mibps: 500,
          encrypted: true,
          lifecycle_policy: [{
            transition_to_ia: "AFTER_60_DAYS"
          }],
          tags: {
            Name: "ml-training-datasets",
            Workload: "machine-learning",
            DataType: "training-datasets",
            Framework: "tensorflow,pytorch"
          }
        })
        
        synthesis
      end
      
      efs = result["resource"]["aws_efs_file_system"]["ml_training"]
      expect(efs["performance_mode"]).to eq("maxIO")
      expect(efs["provisioned_throughput_in_mibps"]).to eq(500)
    end
    
    it "synthesizes web content delivery storage" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:web_content, {
          creation_token: "web-content-storage",
          performance_mode: "generalPurpose",
          throughput_mode: "bursting",
          encrypted: true,
          lifecycle_policy: [
            { transition_to_ia: "AFTER_30_DAYS" },
            { transition_to_archive: "AFTER_180_DAYS" }
          ],
          backup_policy: { status: "ENABLED" },
          tags: {
            Name: "web-static-content",
            Purpose: "content-delivery",
            WebServer: "nginx",
            AutoScale: "enabled"
          }
        })
        
        synthesis
      end
      
      efs = result["resource"]["aws_efs_file_system"]["web_content"]
      expect(efs["lifecycle_policy"]).to have(2).items
      expect(efs["backup_policy"]["status"]).to eq("ENABLED")
    end
    
    it "synthesizes development environment storage" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:dev_storage, {
          creation_token: "dev-team-storage",
          availability_zone_name: "us-east-1a",
          performance_mode: "generalPurpose",
          throughput_mode: "bursting",
          lifecycle_policy: [{
            transition_to_ia: "AFTER_1_DAY"
          }],
          tags: {
            Name: "dev-team-shared",
            Environment: "development",
            Team: "platform-engineering",
            AutoDelete: "true",
            CreatedDate: "2023-11-20"
          }
        })
        
        synthesis
      end
      
      efs = result["resource"]["aws_efs_file_system"]["dev_storage"]
      expect(efs["availability_zone_name"]).to eq("us-east-1a") # One Zone for cost savings
      expect(efs["encrypted"]).to eq(false) # Default for dev
      expect(efs["tags"]["AutoDelete"]).to eq("true")
    end
  end
  
  describe "tag synthesis" do
    it "synthesizes comprehensive tags" do
      result = synthesizer.instance_eval do
        aws_efs_file_system(:tagged_efs, {
          creation_token: "production-efs",
          encrypted: true,
          performance_mode: "generalPurpose",
          throughput_mode: "elastic",
          tags: {
            Name: "production-shared-storage",
            Environment: "production",
            Application: "content-management",
            Team: "platform",
            CostCenter: "engineering",
            DataClassification: "internal",
            BackupSchedule: "daily",
            Compliance: "soc2",
            MonitoringEnabled: "true"
          }
        })
        
        synthesis
      end
      
      tags = result["resource"]["aws_efs_file_system"]["tagged_efs"]["tags"]
      expect(tags).to include(
        Name: "production-shared-storage",
        Environment: "production",
        Application: "content-management",
        Team: "platform"
      )
    end
  end
end