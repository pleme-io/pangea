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
require 'pangea/resources/aws_fsx_lustre_filesystem/resource'
require 'terraform-synthesizer'

RSpec.describe 'aws_fsx_lustre_filesystem synthesis' do
  include Pangea::Resources::AWS
  
  let(:synthesizer) { TerraformSynthesizer.new }
  
  describe 'terraform synthesis' do
    context 'minimal SCRATCH configuration' do
      it 'generates correct terraform JSON' do
        synthesizer.synthesize do
          aws_fsx_lustre_filesystem(:scratch_fs, {
            storage_capacity: 1200,
            subnet_ids: ["subnet-12345678"]
          })
        end
        
        result = synthesizer.synthesis
        fsx = result[:resource][:aws_fsx_lustre_file_system][:scratch_fs]
        
        expect(fsx[:storage_capacity]).to eq(1200)
        expect(fsx[:storage_type]).to eq("SSD")
        expect(fsx[:deployment_type]).to eq("SCRATCH_2")
        expect(fsx[:subnet_ids]).to eq(["subnet-12345678"])
        expect(fsx[:file_system_type_version]).to eq("2.15")
        
        # Should not include optional fields
        expect(fsx[:per_unit_storage_throughput]).to be_nil
        expect(fsx[:automatic_backup_retention_days]).to be_nil
      end
    end
    
    context 'PERSISTENT with full configuration' do
      it 'generates comprehensive terraform configuration' do
        synthesizer.synthesize do
          aws_fsx_lustre_filesystem(:persistent_fs, {
            storage_capacity: 9600,
            subnet_ids: ["subnet-12345678", "subnet-87654321"],
            security_group_ids: ["sg-12345678"],
            deployment_type: "PERSISTENT_1",
            storage_type: "SSD",
            per_unit_storage_throughput: 500,
            import_path: "s3://bucket/import",
            export_path: "s3://bucket/export",
            auto_import_policy: "NEW_CHANGED",
            imported_file_chunk_size: 1024,
            automatic_backup_retention_days: 7,
            daily_automatic_backup_start_time: "05:00",
            copy_tags_to_backups: true,
            data_compression_type: "LZ4",
            kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678",
            weekly_maintenance_start_time: "6:00:00",
            tags: {
              Name: "ML Training Storage",
              Environment: "production"
            }
          })
        end
        
        result = synthesizer.synthesis
        fsx = result[:resource][:aws_fsx_lustre_file_system][:persistent_fs]
        
        # Core configuration
        expect(fsx[:storage_capacity]).to eq(9600)
        expect(fsx[:deployment_type]).to eq("PERSISTENT_1")
        expect(fsx[:storage_type]).to eq("SSD")
        expect(fsx[:per_unit_storage_throughput]).to eq(500)
        
        # Network configuration
        expect(fsx[:subnet_ids]).to eq(["subnet-12345678", "subnet-87654321"])
        expect(fsx[:security_group_ids]).to eq(["sg-12345678"])
        
        # S3 integration
        expect(fsx[:import_path]).to eq("s3://bucket/import")
        expect(fsx[:export_path]).to eq("s3://bucket/export")
        expect(fsx[:auto_import_policy]).to eq("NEW_CHANGED")
        expect(fsx[:imported_file_chunk_size]).to eq(1024)
        
        # Backup configuration
        expect(fsx[:automatic_backup_retention_days]).to eq(7)
        expect(fsx[:daily_automatic_backup_start_time]).to eq("05:00")
        expect(fsx[:copy_tags_to_backups]).to be true
        
        # Additional features
        expect(fsx[:data_compression_type]).to eq("LZ4")
        expect(fsx[:kms_key_id]).to include("key/12345678")
        expect(fsx[:weekly_maintenance_start_time]).to eq("6:00:00")
        
        # Tags
        expect(fsx[:tags][:Name]).to eq("ML Training Storage")
        expect(fsx[:tags][:Environment]).to eq("production")
      end
    end
    
    context 'HDD with drive cache' do
      it 'generates HDD-specific configuration' do
        synthesizer.synthesize do
          aws_fsx_lustre_filesystem(:hdd_fs, {
            storage_capacity: 12000,
            subnet_ids: ["subnet-12345678"],
            deployment_type: "PERSISTENT_1",
            storage_type: "HDD",
            per_unit_storage_throughput: 40,
            drive_cache_type: "READ"
          })
        end
        
        result = synthesizer.synthesis
        fsx = result[:resource][:aws_fsx_lustre_file_system][:hdd_fs]
        
        expect(fsx[:storage_type]).to eq("HDD")
        expect(fsx[:storage_capacity]).to eq(12000)
        expect(fsx[:per_unit_storage_throughput]).to eq(40)
        expect(fsx[:drive_cache_type]).to eq("READ")
      end
    end
    
    context 'conditional field inclusion' do
      it 'excludes PERSISTENT-only fields for SCRATCH' do
        synthesizer.synthesize do
          aws_fsx_lustre_filesystem(:scratch_test, {
            storage_capacity: 2400,
            subnet_ids: ["subnet-12345678"],
            deployment_type: "SCRATCH_2"
          })
        end
        
        result = synthesizer.synthesis
        fsx = result[:resource][:aws_fsx_lustre_file_system][:scratch_test]
        
        # These should not be present for SCRATCH
        expect(fsx[:per_unit_storage_throughput]).to be_nil
        expect(fsx[:automatic_backup_retention_days]).to be_nil
        expect(fsx[:daily_automatic_backup_start_time]).to be_nil
        expect(fsx[:copy_tags_to_backups]).to be_nil
      end
      
      it 'excludes drive cache for SSD storage' do
        synthesizer.synthesize do
          aws_fsx_lustre_filesystem(:ssd_test, {
            storage_capacity: 1200,
            subnet_ids: ["subnet-12345678"],
            storage_type: "SSD"
          })
        end
        
        result = synthesizer.synthesis
        fsx = result[:resource][:aws_fsx_lustre_file_system][:ssd_test]
        
        expect(fsx[:drive_cache_type]).to be_nil
      end
      
      it 'excludes default values from output' do
        synthesizer.synthesize do
          aws_fsx_lustre_filesystem(:defaults_test, {
            storage_capacity: 1200,
            subnet_ids: ["subnet-12345678"],
            data_compression_type: "NONE"  # Default value
          })
        end
        
        result = synthesizer.synthesis
        fsx = result[:resource][:aws_fsx_lustre_file_system][:defaults_test]
        
        # Default compression type should not be included
        expect(fsx[:data_compression_type]).to be_nil
      end
    end
    
    context 'reference integration' do
      it 'supports references to other resources' do
        synthesizer.synthesize do
          # Simulate VPC and subnet references
          vpc_id = "${aws_vpc.main.id}"
          subnet_id = "${aws_subnet.private.id}"
          kms_key_id = "${aws_kms_key.fsx.arn}"
          sg_id = "${aws_security_group.fsx.id}"
          
          aws_fsx_lustre_filesystem(:integrated_fs, {
            storage_capacity: 1200,
            subnet_ids: [subnet_id],
            security_group_ids: [sg_id],
            kms_key_id: kms_key_id
          })
        end
        
        result = synthesizer.synthesis
        fsx = result[:resource][:aws_fsx_lustre_file_system][:integrated_fs]
        
        expect(fsx[:subnet_ids]).to eq(["${aws_subnet.private.id}"])
        expect(fsx[:security_group_ids]).to eq(["${aws_security_group.fsx.id}"])
        expect(fsx[:kms_key_id]).to eq("${aws_kms_key.fsx.arn}")
      end
    end
    
    context 'complex deployment scenarios' do
      it 'generates HPC scratch configuration' do
        synthesizer.synthesize do
          aws_fsx_lustre_filesystem(:hpc_scratch, {
            storage_capacity: 57600,  # 57.6 TB
            subnet_ids: ["subnet-hpc-1", "subnet-hpc-2"],
            deployment_type: "SCRATCH_2",
            data_compression_type: "LZ4",
            tags: {
              Project: "Genomics",
              CostCenter: "Research",
              AutoDelete: "true"
            }
          })
        end
        
        result = synthesizer.synthesis
        fsx = result[:resource][:aws_fsx_lustre_file_system][:hpc_scratch]
        
        expect(fsx[:storage_capacity]).to eq(57600)
        expect(fsx[:deployment_type]).to eq("SCRATCH_2")
        expect(fsx[:data_compression_type]).to eq("LZ4")
        expect(fsx[:tags][:Project]).to eq("Genomics")
      end
      
      it 'generates ML training pipeline configuration' do
        synthesizer.synthesize do
          aws_fsx_lustre_filesystem(:ml_training, {
            storage_capacity: 19200,
            subnet_ids: ["subnet-ml-1"],
            deployment_type: "PERSISTENT_2",
            storage_type: "SSD",
            per_unit_storage_throughput: 1000,
            import_path: "s3://ml-datasets/imagenet",
            export_path: "s3://ml-models/trained",
            auto_import_policy: "NEW_CHANGED_DELETED",
            automatic_backup_retention_days: 30,
            data_compression_type: "LZ4"
          })
        end
        
        result = synthesizer.synthesis
        fsx = result[:resource][:aws_fsx_lustre_file_system][:ml_training]
        
        expect(fsx[:per_unit_storage_throughput]).to eq(1000)
        expect(fsx[:auto_import_policy]).to eq("NEW_CHANGED_DELETED")
        expect(fsx[:automatic_backup_retention_days]).to eq(30)
      end
      
      it 'generates media processing configuration' do
        synthesizer.synthesize do
          aws_fsx_lustre_filesystem(:render_storage, {
            storage_capacity: 72000,  # 72 TB HDD
            subnet_ids: ["subnet-render-1", "subnet-render-2"],
            deployment_type: "PERSISTENT_1",
            storage_type: "HDD",
            per_unit_storage_throughput: 40,
            drive_cache_type: "READ",
            import_path: "s3://media-assets/raw",
            export_path: "s3://media-assets/rendered",
            weekly_maintenance_start_time: "7:00:00"
          })
        end
        
        result = synthesizer.synthesis
        fsx = result[:resource][:aws_fsx_lustre_file_system][:render_storage]
        
        expect(fsx[:storage_capacity]).to eq(72000)
        expect(fsx[:storage_type]).to eq("HDD")
        expect(fsx[:drive_cache_type]).to eq("READ")
        expect(fsx[:weekly_maintenance_start_time]).to eq("7:00:00")
      end
    end
  end
  
  describe 'error handling in synthesis' do
    it 'prevents invalid terraform generation' do
      expect {
        synthesizer.synthesize do
          aws_fsx_lustre_filesystem(:invalid, {
            storage_capacity: 5000,  # Invalid
            subnet_ids: ["subnet-12345678"],
            storage_type: "SSD"
          })
        end
      }.to raise_error(Dry::Struct::Error)
    end
  end
end