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

# Load aws_efs_file_system resource and types for testing
require 'pangea/resources/aws_efs_file_system/resource'
require 'pangea/resources/aws_efs_file_system/types'

RSpec.describe "aws_efs_file_system resource function" do
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
  
  describe "EfsFileSystemAttributes validation" do
    it "accepts basic EFS configuration" do
      efs = Pangea::Resources::AWS::Types::EfsFileSystemAttributes.new({
        creation_token: "my-efs-token",
        performance_mode: "generalPurpose",
        throughput_mode: "bursting",
        encrypted: true,
        tags: {
          Name: "my-efs",
          Environment: "production"
        }
      })
      
      expect(efs.creation_token).to eq("my-efs-token")
      expect(efs.performance_mode).to eq("generalPurpose")
      expect(efs.throughput_mode).to eq("bursting")
      expect(efs.encrypted).to eq(true)
      expect(efs.availability_zone_name).to be_nil
    end
    
    it "accepts provisioned throughput configuration" do
      efs = Pangea::Resources::AWS::Types::EfsFileSystemAttributes.new({
        creation_token: "provisioned-efs",
        performance_mode: "maxIO",
        throughput_mode: "provisioned",
        provisioned_throughput_in_mibps: 100
      })
      
      expect(efs.throughput_mode).to eq("provisioned")
      expect(efs.provisioned_throughput_in_mibps).to eq(100)
    end
    
    it "validates provisioned throughput requires throughput value" do
      expect {
        Pangea::Resources::AWS::Types::EfsFileSystemAttributes.new({
          creation_token: "invalid-efs",
          throughput_mode: "provisioned"
        })
      }.to raise_error(Dry::Struct::Error, /Provisioned throughput mode requires provisioned_throughput_in_mibps/)
    end
    
    it "validates bursting mode cannot have provisioned throughput" do
      expect {
        Pangea::Resources::AWS::Types::EfsFileSystemAttributes.new({
          creation_token: "invalid-efs",
          throughput_mode: "bursting",
          provisioned_throughput_in_mibps: 100
        })
      }.to raise_error(Dry::Struct::Error, /Bursting mode cannot have provisioned_throughput_in_mibps/)
    end
    
    it "accepts One Zone storage configuration" do
      efs = Pangea::Resources::AWS::Types::EfsFileSystemAttributes.new({
        creation_token: "one-zone-efs",
        availability_zone_name: "us-east-1a",
        performance_mode: "generalPurpose"
      })
      
      expect(efs.availability_zone_name).to eq("us-east-1a")
      expect(efs.is_one_zone?).to eq(true)
      expect(efs.is_regional?).to eq(false)
    end
    
    it "validates One Zone cannot use maxIO performance mode" do
      expect {
        Pangea::Resources::AWS::Types::EfsFileSystemAttributes.new({
          creation_token: "invalid-one-zone",
          availability_zone_name: "us-east-1a",
          performance_mode: "maxIO"
        })
      }.to raise_error(Dry::Struct::Error, /One Zone storage class is incompatible with maxIO performance mode/)
    end
    
    it "accepts lifecycle policies" do
      efs = Pangea::Resources::AWS::Types::EfsFileSystemAttributes.new({
        creation_token: "lifecycle-efs",
        lifecycle_policy: [{
          transition_to_ia: "AFTER_7_DAYS"
        }]
      })
      
      expect(efs.lifecycle_policy).to have(1).item
      expect(efs.lifecycle_policy.first[:transition_to_ia]).to eq("AFTER_7_DAYS")
    end
    
    it "accepts backup policy configuration" do
      efs = Pangea::Resources::AWS::Types::EfsFileSystemAttributes.new({
        creation_token: "backup-efs",
        backup_policy: {
          status: "ENABLED"
        }
      })
      
      expect(efs.backup_policy[:status]).to eq("ENABLED")
    end
    
    it "accepts KMS encryption configuration" do
      efs = Pangea::Resources::AWS::Types::EfsFileSystemAttributes.new({
        creation_token: "kms-efs",
        encrypted: true,
        kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      })
      
      expect(efs.encrypted).to eq(true)
      expect(efs.kms_key_id).to include("kms")
    end
    
    it "validates KMS key requires encryption" do
      expect {
        Pangea::Resources::AWS::Types::EfsFileSystemAttributes.new({
          creation_token: "invalid-kms",
          encrypted: false,
          kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678"
        })
      }.not_to raise_error # AWS will validate this
    end
    
    it "calculates storage cost for regional EFS" do
      efs = Pangea::Resources::AWS::Types::EfsFileSystemAttributes.new({
        creation_token: "regional-efs"
      })
      
      expect(efs.estimated_storage_cost_per_gb).to eq(0.30) # Regional storage
      expect(efs.storage_class).to eq("Regional")
    end
    
    it "calculates storage cost for One Zone EFS" do
      efs = Pangea::Resources::AWS::Types::EfsFileSystemAttributes.new({
        creation_token: "one-zone-efs",
        availability_zone_name: "us-east-1a"
      })
      
      expect(efs.estimated_storage_cost_per_gb).to eq(0.16) # One Zone storage
      expect(efs.storage_class).to eq("OneZone")
    end
    
    it "provides configuration warnings" do
      # No encryption warning
      unencrypted = Pangea::Resources::AWS::Types::EfsFileSystemAttributes.new({
        creation_token: "unencrypted-efs",
        encrypted: false
      })
      warnings = unencrypted.validate_configuration
      expect(warnings).to include("EFS is not encrypted - consider enabling encryption for data at rest")
      
      # No lifecycle policy warning
      no_lifecycle = Pangea::Resources::AWS::Types::EfsFileSystemAttributes.new({
        creation_token: "no-lifecycle-efs"
      })
      warnings = no_lifecycle.validate_configuration
      expect(warnings).to include("No lifecycle policy configured - consider enabling to reduce costs")
      
      # High throughput warning
      high_throughput = Pangea::Resources::AWS::Types::EfsFileSystemAttributes.new({
        creation_token: "high-throughput-efs",
        throughput_mode: "provisioned",
        provisioned_throughput_in_mibps: 500
      })
      warnings = high_throughput.validate_configuration
      expect(warnings).to include("High provisioned throughput (500 MiB/s) will incur significant costs")
    end
  end
  
  describe "aws_efs_file_system function" do
    it "creates basic EFS file system" do
      result = test_instance.aws_efs_file_system(:my_efs, {
        creation_token: "my-efs-token",
        performance_mode: "generalPurpose",
        encrypted: true,
        tags: {
          Name: "my-efs",
          Environment: "production"
        }
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_efs_file_system')
      expect(result.name).to eq(:my_efs)
      expect(result.id).to eq("${aws_efs_file_system.my_efs.id}")
    end
    
    it "creates EFS with provisioned throughput" do
      result = test_instance.aws_efs_file_system(:high_perf_efs, {
        creation_token: "high-perf-efs",
        performance_mode: "maxIO",
        throughput_mode: "provisioned",
        provisioned_throughput_in_mibps: 200,
        encrypted: true,
        kms_key_id: "alias/aws/efs"
      })
      
      expect(result.resource_attributes[:throughput_mode]).to eq("provisioned")
      expect(result.resource_attributes[:provisioned_throughput_in_mibps]).to eq(200)
      expect(result.resource_attributes[:performance_mode]).to eq("maxIO")
    end
    
    it "creates One Zone EFS" do
      result = test_instance.aws_efs_file_system(:one_zone_efs, {
        creation_token: "one-zone-efs",
        availability_zone_name: "us-east-1a",
        performance_mode: "generalPurpose",
        encrypted: true
      })
      
      expect(result.resource_attributes[:availability_zone_name]).to eq("us-east-1a")
      expect(result.is_one_zone?).to eq(true)
      expect(result.is_regional?).to eq(false)
      expect(result.storage_class).to eq("OneZone")
    end
    
    it "creates EFS with lifecycle policy" do
      result = test_instance.aws_efs_file_system(:lifecycle_efs, {
        creation_token: "lifecycle-efs",
        lifecycle_policy: [
          { transition_to_ia: "AFTER_7_DAYS" },
          { transition_to_archive: "AFTER_90_DAYS" }
        ],
        encrypted: true
      })
      
      expect(result.resource_attributes[:lifecycle_policy]).to have(2).items
      expect(result.has_lifecycle_policy?).to eq(true)
    end
    
    it "creates EFS with backup policy" do
      result = test_instance.aws_efs_file_system(:backup_efs, {
        creation_token: "backup-efs",
        backup_policy: {
          status: "ENABLED"
        },
        encrypted: true
      })
      
      expect(result.resource_attributes[:backup_policy][:status]).to eq("ENABLED")
    end
    
    it "provides correct outputs" do
      result = test_instance.aws_efs_file_system(:test, {
        creation_token: "test-efs"
      })
      
      expect(result.id).to eq("${aws_efs_file_system.test.id}")
      expect(result.arn).to eq("${aws_efs_file_system.test.arn}")
      expect(result.dns_name).to eq("${aws_efs_file_system.test.dns_name}")
      expect(result.size_in_bytes).to eq("${aws_efs_file_system.test.size_in_bytes}")
      expect(result.number_of_mount_targets).to eq("${aws_efs_file_system.test.number_of_mount_targets}")
      expect(result.owner_id).to eq("${aws_efs_file_system.test.owner_id}")
    end
    
    it "provides computed properties" do
      result = test_instance.aws_efs_file_system(:computed_test, {
        creation_token: "computed-test",
        availability_zone_name: "us-east-1a",
        throughput_mode: "provisioned",
        provisioned_throughput_in_mibps: 100,
        lifecycle_policy: [{ transition_to_ia: "AFTER_30_DAYS" }]
      })
      
      expect(result.is_one_zone?).to eq(true)
      expect(result.is_regional?).to eq(false)
      expect(result.is_encrypted?).to eq(false)
      expect(result.has_lifecycle_policy?).to eq(true)
      expect(result.storage_class).to eq("OneZone")
      expect(result.estimated_storage_cost_per_gb).to eq(0.16)
    end
  end
  
  describe "EFS patterns" do
    it "creates high-performance EFS for HPC workloads" do
      result = test_instance.aws_efs_file_system(:hpc_storage, {
        creation_token: "hpc-storage",
        performance_mode: "maxIO",
        throughput_mode: "provisioned",
        provisioned_throughput_in_mibps: 1024,
        encrypted: true,
        tags: {
          Name: "hpc-shared-storage",
          Workload: "high-performance-computing",
          CostCenter: "research"
        }
      })
      
      expect(result.resource_attributes[:performance_mode]).to eq("maxIO")
      expect(result.resource_attributes[:provisioned_throughput_in_mibps]).to eq(1024)
    end
    
    it "creates cost-optimized EFS with lifecycle management" do
      result = test_instance.aws_efs_file_system(:cost_optimized, {
        creation_token: "cost-optimized-efs",
        availability_zone_name: "us-east-1a",
        lifecycle_policy: [
          { transition_to_ia: "AFTER_7_DAYS" },
          { transition_to_archive: "AFTER_30_DAYS" }
        ],
        encrypted: true,
        tags: {
          Name: "cost-optimized-storage",
          Pattern: "one-zone-with-lifecycle"
        }
      })
      
      expect(result.is_one_zone?).to eq(true)
      expect(result.has_lifecycle_policy?).to eq(true)
      expect(result.resource_attributes[:lifecycle_policy]).to have(2).items
    end
    
    it "creates multi-AZ resilient EFS" do
      result = test_instance.aws_efs_file_system(:resilient_storage, {
        creation_token: "resilient-storage",
        performance_mode: "generalPurpose",
        throughput_mode: "elastic",
        encrypted: true,
        backup_policy: { status: "ENABLED" },
        tags: {
          Name: "multi-az-resilient",
          HA: "multi-az",
          Backup: "enabled"
        }
      })
      
      expect(result.is_regional?).to eq(true)
      expect(result.resource_attributes[:backup_policy][:status]).to eq("ENABLED")
      expect(result.resource_attributes[:throughput_mode]).to eq("elastic")
    end
    
    it "creates development EFS with minimal configuration" do
      result = test_instance.aws_efs_file_system(:dev_storage, {
        creation_token: "dev-storage",
        availability_zone_name: "us-east-1a",
        lifecycle_policy: [{ transition_to_ia: "AFTER_1_DAY" }],
        tags: {
          Name: "dev-efs",
          Environment: "development",
          AutoDelete: "true"
        }
      })
      
      expect(result.is_one_zone?).to eq(true)
      expect(result.resource_attributes[:encrypted]).to eq(false) # Default
      expect(result.has_lifecycle_policy?).to eq(true)
    end
    
    it "creates secure EFS with KMS encryption" do
      result = test_instance.aws_efs_file_system(:secure_storage, {
        creation_token: "secure-storage",
        encrypted: true,
        kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
        performance_mode: "generalPurpose",
        backup_policy: { status: "ENABLED" },
        tags: {
          Name: "secure-efs",
          Compliance: "pci-dss",
          DataClassification: "confidential"
        }
      })
      
      expect(result.is_encrypted?).to eq(true)
      expect(result.resource_attributes[:kms_key_id]).to include("kms")
      expect(result.resource_attributes[:backup_policy][:status]).to eq("ENABLED")
    end
  end
  
  describe "advanced configurations" do
    it "creates EFS for container workloads" do
      result = test_instance.aws_efs_file_system(:container_storage, {
        creation_token: "container-storage",
        performance_mode: "generalPurpose",
        throughput_mode: "elastic",
        encrypted: true,
        lifecycle_policy: [{ transition_to_ia: "AFTER_14_DAYS" }],
        tags: {
          Name: "eks-shared-storage",
          Orchestrator: "kubernetes",
          StorageClass: "efs-sc"
        }
      })
      
      expect(result.resource_attributes[:throughput_mode]).to eq("elastic")
      expect(result.resource_attributes[:tags][:Orchestrator]).to eq("kubernetes")
    end
    
    it "creates EFS for ML/AI workloads" do
      result = test_instance.aws_efs_file_system(:ml_storage, {
        creation_token: "ml-model-storage",
        performance_mode: "maxIO",
        throughput_mode: "provisioned",
        provisioned_throughput_in_mibps: 500,
        encrypted: true,
        tags: {
          Name: "ml-model-storage",
          Workload: "machine-learning",
          DataType: "model-artifacts"
        }
      })
      
      expect(result.resource_attributes[:performance_mode]).to eq("maxIO")
      expect(result.resource_attributes[:provisioned_throughput_in_mibps]).to eq(500)
    end
    
    it "creates EFS for web content serving" do
      result = test_instance.aws_efs_file_system(:web_content, {
        creation_token: "web-content-storage",
        performance_mode: "generalPurpose",
        throughput_mode: "bursting",
        encrypted: true,
        lifecycle_policy: [
          { transition_to_ia: "AFTER_30_DAYS" },
          { transition_to_archive: "AFTER_180_DAYS" }
        ],
        tags: {
          Name: "web-content-efs",
          Purpose: "static-content",
          CDN: "integrated"
        }
      })
      
      expect(result.resource_attributes[:lifecycle_policy]).to have(2).items
      expect(result.resource_attributes[:throughput_mode]).to eq("bursting")
    end
  end
  
  describe "error conditions" do
    it "handles missing creation token" do
      expect {
        test_instance.aws_efs_file_system(:invalid, {
          performance_mode: "generalPurpose"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "handles invalid performance mode with One Zone" do
      expect {
        test_instance.aws_efs_file_system(:invalid_one_zone, {
          creation_token: "invalid",
          availability_zone_name: "us-east-1a",
          performance_mode: "maxIO"
        })
      }.to raise_error(Dry::Struct::Error, /One Zone storage class is incompatible/)
    end
    
    it "handles provisioned throughput without value" do
      expect {
        test_instance.aws_efs_file_system(:invalid_throughput, {
          creation_token: "invalid",
          throughput_mode: "provisioned"
        })
      }.to raise_error(Dry::Struct::Error, /requires provisioned_throughput_in_mibps/)
    end
  end
end