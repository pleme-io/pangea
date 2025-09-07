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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require_relative 'types'

module Pangea
  module Resources
    module AWS
      # Creates a fully managed, high-performance FSx for Lustre file system
      #
      # @param name [Symbol] The unique name for this resource instance
      # @param attributes [Hash] FSx Lustre file system configuration
      # @return [ResourceReference] Reference object with FSx Lustre outputs
      #
      # @example Basic SCRATCH deployment for HPC workloads
      #   fsx = aws_fsx_lustre_filesystem(:hpc_storage, {
      #     storage_capacity: 1200,
      #     subnet_ids: [subnet_ref.id],
      #     deployment_type: "SCRATCH_2"
      #   })
      #
      # @example PERSISTENT deployment with S3 integration
      #   fsx = aws_fsx_lustre_filesystem(:ml_training, {
      #     storage_capacity: 9600,
      #     subnet_ids: [subnet_ref.id],
      #     deployment_type: "PERSISTENT_1",
      #     storage_type: "SSD",
      #     per_unit_storage_throughput: 200,
      #     import_path: "s3://my-bucket/training-data",
      #     export_path: "s3://my-bucket/training-output",
      #     auto_import_policy: "NEW_CHANGED"
      #   })
      #
      # @example High-capacity HDD storage with backups
      #   fsx = aws_fsx_lustre_filesystem(:archive_storage, {
      #     storage_capacity: 12000,
      #     subnet_ids: [subnet_ref.id],
      #     deployment_type: "PERSISTENT_1",
      #     storage_type: "HDD",
      #     per_unit_storage_throughput: 40,
      #     automatic_backup_retention_days: 7,
      #     drive_cache_type: "READ"
      #   })
      def aws_fsx_lustre_filesystem(name, attributes = {})
        # Validate and transform attributes
        fsx_attrs = AWS::Types::Types::FsxLustreFileSystemAttributes.new(attributes)
        
        # Create FSx Lustre resource
        resource(:aws_fsx_lustre_file_system, name) do
          # Storage configuration
          storage_capacity fsx_attrs.storage_capacity
          storage_type fsx_attrs.storage_type
          deployment_type fsx_attrs.deployment_type
          
          # Network configuration
          subnet_ids fsx_attrs.subnet_ids
          security_group_ids fsx_attrs.security_group_ids if fsx_attrs.security_group_ids
          
          # S3 data repository configuration
          import_path fsx_attrs.import_path if fsx_attrs.import_path
          export_path fsx_attrs.export_path if fsx_attrs.export_path
          auto_import_policy fsx_attrs.auto_import_policy if fsx_attrs.auto_import_policy
          imported_file_chunk_size fsx_attrs.imported_file_chunk_size if fsx_attrs.imported_file_chunk_size
          
          # Performance configuration for PERSISTENT
          if fsx_attrs.is_persistent? && fsx_attrs.per_unit_storage_throughput
            per_unit_storage_throughput fsx_attrs.per_unit_storage_throughput
          end
          
          # Backup configuration for PERSISTENT
          if fsx_attrs.is_persistent?
            automatic_backup_retention_days fsx_attrs.automatic_backup_retention_days if fsx_attrs.automatic_backup_retention_days
            daily_automatic_backup_start_time fsx_attrs.daily_automatic_backup_start_time if fsx_attrs.daily_automatic_backup_start_time
            copy_tags_to_backups fsx_attrs.copy_tags_to_backups if !fsx_attrs.copy_tags_to_backups.nil?
          end
          
          # Additional configurations
          data_compression_type fsx_attrs.data_compression_type if fsx_attrs.data_compression_type != "NONE"
          drive_cache_type fsx_attrs.drive_cache_type if fsx_attrs.drive_cache_type && fsx_attrs.storage_type == "HDD"
          kms_key_id fsx_attrs.kms_key_id if fsx_attrs.kms_key_id
          file_system_type_version fsx_attrs.file_system_type_version
          weekly_maintenance_start_time fsx_attrs.weekly_maintenance_start_time if fsx_attrs.weekly_maintenance_start_time
          
          # Tags
          if fsx_attrs.tags.any?
            tags do
              fsx_attrs.tags.each { |key, value| public_send(key, value) }
            end
          end
        end
        
        # Return reference with FSx Lustre-specific outputs
        ref = ResourceReference.new(
          type: 'aws_fsx_lustre_file_system',
          name: name,
          resource_attributes: fsx_attrs.to_h,
          outputs: {
            # Core identifiers
            id: "${aws_fsx_lustre_file_system.#{name}.id}",
            arn: "${aws_fsx_lustre_file_system.#{name}.arn}",
            dns_name: "${aws_fsx_lustre_file_system.#{name}.dns_name}",
            
            # Mount information
            mount_name: "${aws_fsx_lustre_file_system.#{name}.mount_name}",
            network_interface_ids: "${aws_fsx_lustre_file_system.#{name}.network_interface_ids}",
            
            # Resource details
            owner_id: "${aws_fsx_lustre_file_system.#{name}.owner_id}",
            vpc_id: "${aws_fsx_lustre_file_system.#{name}.vpc_id}",
            weekly_maintenance_start_time: "${aws_fsx_lustre_file_system.#{name}.weekly_maintenance_start_time}",
            
            # Configuration outputs
            deployment_type: fsx_attrs.deployment_type,
            storage_type: fsx_attrs.storage_type,
            storage_capacity: fsx_attrs.storage_capacity,
            per_unit_storage_throughput: fsx_attrs.per_unit_storage_throughput
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:is_persistent?) { fsx_attrs.is_persistent? }
        ref.define_singleton_method(:is_scratch?) { fsx_attrs.is_scratch? }
        ref.define_singleton_method(:supports_backups?) { fsx_attrs.supports_backups? }
        ref.define_singleton_method(:supports_throughput_configuration?) { fsx_attrs.supports_throughput_configuration? }
        ref.define_singleton_method(:supports_drive_cache?) { fsx_attrs.supports_drive_cache? }
        ref.define_singleton_method(:estimated_baseline_throughput) { fsx_attrs.estimated_baseline_throughput }
        ref.define_singleton_method(:estimated_monthly_cost) { fsx_attrs.estimated_monthly_cost }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)