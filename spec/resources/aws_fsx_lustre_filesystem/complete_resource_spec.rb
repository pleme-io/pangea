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

RSpec.describe 'aws_fsx_lustre_filesystem' do
  include Pangea::Resources::AWS
  
  describe 'resource function' do
    context 'with minimal SCRATCH configuration' do
      it 'creates FSx Lustre with defaults' do
        ref = aws_fsx_lustre_filesystem(:test_fsx, {
          storage_capacity: 1200,
          subnet_ids: ["subnet-12345678"]
        })
        
        expect(ref).to be_a(Pangea::Resources::ResourceReference)
        expect(ref.type).to eq('aws_fsx_lustre_file_system')
        expect(ref.name).to eq(:test_fsx)
        expect(ref[:storage_type]).to eq("SSD")
        expect(ref[:deployment_type]).to eq("SCRATCH_2")
      end
    end
    
    context 'with PERSISTENT SSD configuration' do
      it 'creates high-performance persistent file system' do
        ref = aws_fsx_lustre_filesystem(:ml_storage, {
          storage_capacity: 9600,
          subnet_ids: ["subnet-12345678", "subnet-87654321"],
          deployment_type: "PERSISTENT_1",
          storage_type: "SSD",
          per_unit_storage_throughput: 500,
          automatic_backup_retention_days: 7,
          data_compression_type: "LZ4"
        })
        
        expect(ref[:storage_capacity]).to eq(9600)
        expect(ref[:deployment_type]).to eq("PERSISTENT_1")
        expect(ref[:per_unit_storage_throughput]).to eq(500)
        expect(ref.is_persistent?).to be true
        expect(ref.supports_backups?).to be true
      end
    end
    
    context 'with PERSISTENT HDD configuration' do
      it 'creates cost-optimized persistent storage' do
        ref = aws_fsx_lustre_filesystem(:archive, {
          storage_capacity: 12000,
          subnet_ids: ["subnet-12345678"],
          deployment_type: "PERSISTENT_2",
          storage_type: "HDD",
          per_unit_storage_throughput: 40,
          drive_cache_type: "READ"
        })
        
        expect(ref[:storage_type]).to eq("HDD")
        expect(ref[:per_unit_storage_throughput]).to eq(40)
        expect(ref.supports_drive_cache?).to be true
      end
    end
    
    context 'with S3 data repository integration' do
      it 'configures import and export paths' do
        ref = aws_fsx_lustre_filesystem(:data_lake, {
          storage_capacity: 2400,
          subnet_ids: ["subnet-12345678"],
          import_path: "s3://my-bucket/data",
          export_path: "s3://my-bucket/results",
          auto_import_policy: "NEW_CHANGED",
          imported_file_chunk_size: 1024
        })
        
        expect(ref.resource_attributes[:import_path]).to eq("s3://my-bucket/data")
        expect(ref.resource_attributes[:export_path]).to eq("s3://my-bucket/results")
        expect(ref.resource_attributes[:auto_import_policy]).to eq("NEW_CHANGED")
      end
    end
    
    context 'with security configuration' do
      it 'applies security groups and encryption' do
        ref = aws_fsx_lustre_filesystem(:secure_fsx, {
          storage_capacity: 1200,
          subnet_ids: ["subnet-12345678"],
          security_group_ids: ["sg-12345678", "sg-87654321"],
          kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234"
        })
        
        expect(ref.resource_attributes[:security_group_ids]).to eq(["sg-12345678", "sg-87654321"])
        expect(ref.resource_attributes[:kms_key_id]).to include("key/12345678-1234")
      end
    end
  end
  
  describe 'type validation' do
    context 'storage capacity validation' do
      it 'validates SSD capacity values' do
        expect {
          aws_fsx_lustre_filesystem(:invalid, {
            storage_capacity: 5000,  # Not a valid SSD capacity
            subnet_ids: ["subnet-12345678"],
            storage_type: "SSD"
          })
        }.to raise_error(Dry::Struct::Error, /capacity must be one of/)
      end
      
      it 'validates HDD capacity multiples' do
        expect {
          aws_fsx_lustre_filesystem(:invalid, {
            storage_capacity: 7000,  # Not a multiple of 6000
            subnet_ids: ["subnet-12345678"],
            storage_type: "HDD"
          })
        }.to raise_error(Dry::Struct::Error, /must be a multiple of 6000/)
      end
      
      it 'accepts valid SSD capacities' do
        [1200, 2400, 4800, 9600, 19200].each do |capacity|
          ref = aws_fsx_lustre_filesystem(:valid, {
            storage_capacity: capacity,
            subnet_ids: ["subnet-12345678"],
            storage_type: "SSD"
          })
          expect(ref[:storage_capacity]).to eq(capacity)
        end
      end
    end
    
    context 'throughput validation' do
      it 'rejects throughput for SCRATCH deployments' do
        expect {
          aws_fsx_lustre_filesystem(:invalid, {
            storage_capacity: 1200,
            subnet_ids: ["subnet-12345678"],
            deployment_type: "SCRATCH_2",
            per_unit_storage_throughput: 200
          })
        }.to raise_error(Dry::Struct::Error, /cannot be specified for SCRATCH/)
      end
      
      it 'validates SSD throughput tiers' do
        expect {
          aws_fsx_lustre_filesystem(:invalid, {
            storage_capacity: 1200,
            subnet_ids: ["subnet-12345678"],
            deployment_type: "PERSISTENT_1",
            storage_type: "SSD",
            per_unit_storage_throughput: 300  # Invalid tier
          })
        }.to raise_error(Dry::Struct::Error, /throughput must be one of/)
      end
      
      it 'validates HDD throughput options' do
        expect {
          aws_fsx_lustre_filesystem(:invalid, {
            storage_capacity: 6000,
            subnet_ids: ["subnet-12345678"],
            deployment_type: "PERSISTENT_1",
            storage_type: "HDD",
            per_unit_storage_throughput: 50  # Invalid for HDD
          })
        }.to raise_error(Dry::Struct::Error, /throughput must be one of/)
      end
    end
    
    context 'deployment type constraints' do
      it 'rejects backup configuration for SCRATCH' do
        expect {
          aws_fsx_lustre_filesystem(:invalid, {
            storage_capacity: 1200,
            subnet_ids: ["subnet-12345678"],
            deployment_type: "SCRATCH_1",
            automatic_backup_retention_days: 7
          })
        }.to raise_error(Dry::Struct::Error, /cannot be set for SCRATCH/)
      end
      
      it 'rejects drive cache for SSD storage' do
        expect {
          aws_fsx_lustre_filesystem(:invalid, {
            storage_capacity: 1200,
            subnet_ids: ["subnet-12345678"],
            storage_type: "SSD",
            drive_cache_type: "READ"
          })
        }.to raise_error(Dry::Struct::Error, /only be specified for HDD/)
      end
    end
    
    context 'backup configuration validation' do
      it 'validates retention days range' do
        expect {
          aws_fsx_lustre_filesystem(:invalid, {
            storage_capacity: 1200,
            subnet_ids: ["subnet-12345678"],
            deployment_type: "PERSISTENT_1",
            automatic_backup_retention_days: 100
          })
        }.to raise_error(Dry::Struct::Error, /must be between 0 and 90/)
      end
    end
    
    context 'S3 integration validation' do
      it 'validates imported file chunk size' do
        expect {
          aws_fsx_lustre_filesystem(:invalid, {
            storage_capacity: 1200,
            subnet_ids: ["subnet-12345678"],
            imported_file_chunk_size: 600000  # Too large
          })
        }.to raise_error(Dry::Struct::Error, /must be between 1 and 512000/)
      end
      
      it 'validates auto import policy values' do
        expect {
          aws_fsx_lustre_filesystem(:invalid, {
            storage_capacity: 1200,
            subnet_ids: ["subnet-12345678"],
            auto_import_policy: "INVALID_POLICY"
          })
        }.to raise_error(Dry::Types::ConstraintError)
      end
    end
  end
  
  describe 'computed properties' do
    context 'deployment type checks' do
      it 'correctly identifies SCRATCH deployments' do
        ref = aws_fsx_lustre_filesystem(:scratch, {
          storage_capacity: 1200,
          subnet_ids: ["subnet-12345678"],
          deployment_type: "SCRATCH_2"
        })
        
        expect(ref.is_scratch?).to be true
        expect(ref.is_persistent?).to be false
        expect(ref.supports_backups?).to be false
      end
      
      it 'correctly identifies PERSISTENT deployments' do
        ref = aws_fsx_lustre_filesystem(:persistent, {
          storage_capacity: 1200,
          subnet_ids: ["subnet-12345678"],
          deployment_type: "PERSISTENT_1"
        })
        
        expect(ref.is_persistent?).to be true
        expect(ref.is_scratch?).to be false
        expect(ref.supports_backups?).to be true
        expect(ref.supports_throughput_configuration?).to be true
      end
    end
    
    context 'throughput estimation' do
      it 'calculates SCRATCH throughput' do
        scratch1 = aws_fsx_lustre_filesystem(:s1, {
          storage_capacity: 2400,
          subnet_ids: ["subnet-12345678"],
          deployment_type: "SCRATCH_1"
        })
        
        scratch2 = aws_fsx_lustre_filesystem(:s2, {
          storage_capacity: 2400,
          subnet_ids: ["subnet-12345678"],
          deployment_type: "SCRATCH_2"
        })
        
        expect(scratch1.estimated_baseline_throughput).to eq(400)  # 200 MB/s per 1.2 TB
        expect(scratch2.estimated_baseline_throughput).to eq(480)  # 240 MB/s per 1.2 TB
      end
      
      it 'calculates PERSISTENT throughput with custom values' do
        ref = aws_fsx_lustre_filesystem(:p1, {
          storage_capacity: 9600,
          subnet_ids: ["subnet-12345678"],
          deployment_type: "PERSISTENT_1",
          per_unit_storage_throughput: 500
        })
        
        # 500 MB/s/TiB * 9.375 TiB = 4687.5 MB/s
        expect(ref.estimated_baseline_throughput).to be_within(1).of(4687.5)
      end
    end
    
    context 'cost estimation' do
      it 'estimates SCRATCH SSD costs' do
        ref = aws_fsx_lustre_filesystem(:scratch, {
          storage_capacity: 1200,
          subnet_ids: ["subnet-12345678"],
          deployment_type: "SCRATCH_2",
          storage_type: "SSD"
        })
        
        cost = ref.estimated_monthly_cost
        expect(cost[:storage]).to eq(168.0)  # $0.140/GB * 1200 GB
        expect(cost[:throughput]).to eq(0.0)
        expect(cost[:total]).to eq(168.0)
      end
      
      it 'estimates PERSISTENT HDD costs' do
        ref = aws_fsx_lustre_filesystem(:persistent, {
          storage_capacity: 6000,
          subnet_ids: ["subnet-12345678"],
          deployment_type: "PERSISTENT_1",
          storage_type: "HDD"
        })
        
        cost = ref.estimated_monthly_cost
        expect(cost[:storage]).to eq(90.0)  # $0.015/GB * 6000 GB
      end
      
      it 'includes throughput costs for higher tiers' do
        ref = aws_fsx_lustre_filesystem(:high_perf, {
          storage_capacity: 1024,  # Exactly 1 TiB
          subnet_ids: ["subnet-12345678"],
          deployment_type: "PERSISTENT_1",
          storage_type: "SSD",
          per_unit_storage_throughput: 1000
        })
        
        cost = ref.estimated_monthly_cost
        expect(cost[:storage]).to eq(148.48)
        expect(cost[:throughput]).to be > 0  # Additional cost for 1000 MB/s tier
      end
    end
  end
  
  describe 'resource outputs' do
    it 'provides comprehensive outputs' do
      ref = aws_fsx_lustre_filesystem(:test, {
        storage_capacity: 1200,
        subnet_ids: ["subnet-12345678"]
      })
      
      # Core outputs
      expect(ref.id).to eq("${aws_fsx_lustre_file_system.test.id}")
      expect(ref.arn).to eq("${aws_fsx_lustre_file_system.test.arn}")
      expect(ref.dns_name).to eq("${aws_fsx_lustre_file_system.test.dns_name}")
      
      # Mount information
      expect(ref.mount_name).to eq("${aws_fsx_lustre_file_system.test.mount_name}")
      expect(ref.network_interface_ids).to eq("${aws_fsx_lustre_file_system.test.network_interface_ids}")
      
      # Resource details
      expect(ref.vpc_id).to eq("${aws_fsx_lustre_file_system.test.vpc_id}")
      expect(ref.owner_id).to eq("${aws_fsx_lustre_file_system.test.owner_id}")
    end
  end
  
  describe 'integration patterns' do
    it 'supports HPC scratch workspace' do
      ref = aws_fsx_lustre_filesystem(:hpc_scratch, {
        storage_capacity: 28800,
        subnet_ids: ["subnet-12345678"],
        deployment_type: "SCRATCH_2",
        data_compression_type: "LZ4",
        tags: {
          Environment: "hpc",
          Workload: "genomics"
        }
      })
      
      expect(ref[:storage_capacity]).to eq(28800)
      expect(ref.resource_attributes[:data_compression_type]).to eq("LZ4")
      expect(ref.estimated_baseline_throughput).to eq(5760)  # High throughput for HPC
    end
    
    it 'supports ML pipeline with S3' do
      ref = aws_fsx_lustre_filesystem(:ml_pipeline, {
        storage_capacity: 19200,
        subnet_ids: ["subnet-12345678"],
        deployment_type: "PERSISTENT_1",
        storage_type: "SSD",
        per_unit_storage_throughput: 500,
        import_path: "s3://ml-data/training",
        export_path: "s3://ml-data/models",
        auto_import_policy: "NEW_CHANGED",
        automatic_backup_retention_days: 7
      })
      
      expect(ref.resource_attributes[:import_path]).to eq("s3://ml-data/training")
      expect(ref.resource_attributes[:export_path]).to eq("s3://ml-data/models")
      expect(ref.supports_backups?).to be true
    end
    
    it 'supports media rendering with drive cache' do
      ref = aws_fsx_lustre_filesystem(:render_farm, {
        storage_capacity: 48000,
        subnet_ids: ["subnet-12345678", "subnet-87654321"],
        deployment_type: "PERSISTENT_1",
        storage_type: "HDD",
        per_unit_storage_throughput: 40,
        drive_cache_type: "READ",
        weekly_maintenance_start_time: "6:00:00"
      })
      
      expect(ref[:storage_type]).to eq("HDD")
      expect(ref.resource_attributes[:drive_cache_type]).to eq("READ")
      expect(ref.supports_drive_cache?).to be true
    end
  end
  
  describe 'edge cases' do
    it 'handles maximum capacity configurations' do
      ref = aws_fsx_lustre_filesystem(:max_ssd, {
        storage_capacity: 115200,  # Maximum SSD capacity
        subnet_ids: ["subnet-12345678"],
        deployment_type: "PERSISTENT_2",
        storage_type: "SSD",
        per_unit_storage_throughput: 1000
      })
      
      expect(ref[:storage_capacity]).to eq(115200)
      expect(ref.estimated_baseline_throughput).to be > 100000  # Very high throughput
    end
    
    it 'handles minimal backup configuration' do
      ref = aws_fsx_lustre_filesystem(:no_backup, {
        storage_capacity: 1200,
        subnet_ids: ["subnet-12345678"],
        deployment_type: "PERSISTENT_1",
        automatic_backup_retention_days: 0  # Disable backups
      })
      
      expect(ref.resource_attributes[:automatic_backup_retention_days]).to eq(0)
    end
    
    it 'handles all compression options' do
      none = aws_fsx_lustre_filesystem(:no_compress, {
        storage_capacity: 1200,
        subnet_ids: ["subnet-12345678"],
        data_compression_type: "NONE"
      })
      
      lz4 = aws_fsx_lustre_filesystem(:compress, {
        storage_capacity: 1200,
        subnet_ids: ["subnet-12345678"],
        data_compression_type: "LZ4"
      })
      
      expect(none.resource_attributes[:data_compression_type]).to eq("NONE")
      expect(lz4.resource_attributes[:data_compression_type]).to eq("LZ4")
    end
  end
end