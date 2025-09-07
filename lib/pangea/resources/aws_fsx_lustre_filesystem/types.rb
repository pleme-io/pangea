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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # FSx Lustre file system resource attributes with validation
        class FsxLustreFileSystemAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Core FSx Lustre attributes
          attribute? :import_path, Resources::Types::String.optional
          attribute? :export_path, Resources::Types::String.optional
          attribute :storage_capacity, Resources::Types::Integer
          attribute :subnet_ids, Resources::Types::Array.of(Resources::Types::String)
          attribute? :security_group_ids, Resources::Types::Array.of(Resources::Types::String).optional
          
          # Storage configuration
          attribute :storage_type, Resources::Types::String.default("SSD").constrained(included_in: ["SSD", "HDD"])
          attribute? :per_unit_storage_throughput, Resources::Types::Integer.optional
          
          # Deployment type
          attribute :deployment_type, Resources::Types::String.default("SCRATCH_2").constrained(included_in: ["SCRATCH_1", "SCRATCH_2", "PERSISTENT_1", "PERSISTENT_2"])
          
          # Data repository configuration  
          attribute? :auto_import_policy, Resources::Types::String.optional.constrained(included_in: ["NONE", "NEW", "NEW_CHANGED", "NEW_CHANGED_DELETED"])
          attribute? :imported_file_chunk_size, Resources::Types::Integer.optional
          
          # Maintenance window
          attribute? :weekly_maintenance_start_time, Resources::Types::String.optional
          
          # Backup configuration (for PERSISTENT types)
          attribute? :automatic_backup_retention_days, Resources::Types::Integer.optional
          attribute? :daily_automatic_backup_start_time, Resources::Types::String.optional
          attribute? :copy_tags_to_backups, Resources::Types::Bool.default(false)
          
          # Data compression
          attribute? :data_compression_type, Resources::Types::String.default("NONE").constrained(included_in: ["NONE", "LZ4"])
          
          # Drive cache (HDD only)
          attribute? :drive_cache_type, Resources::Types::String.optional.constrained(included_in: ["NONE", "READ"])
          
          # KMS encryption
          attribute? :kms_key_id, Resources::Types::String.optional
          
          # Lustre configuration
          attribute? :file_system_type_version, Resources::Types::String.default("2.15")
          
          # Tags
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Call parent to get defaults applied
            instance = super(attrs)
            
            # Validate storage capacity based on storage type
            if instance.storage_type == "SSD"
              valid_capacities = [1200, 2400, 4800, 9600, 19200, 28800, 38400, 57600, 76800, 96000, 115200]
              unless valid_capacities.include?(instance.storage_capacity)
                raise Dry::Struct::Error, "For SSD storage, capacity must be one of: #{valid_capacities.join(', ')} GB"
              end
            elsif instance.storage_type == "HDD"
              if instance.storage_capacity < 6000 || instance.storage_capacity % 6000 != 0
                raise Dry::Struct::Error, "For HDD storage, capacity must be a multiple of 6000 GB (minimum 6000 GB)"
              end
            end
            
            # Validate throughput based on deployment type and storage type
            if instance.deployment_type.start_with?("PERSISTENT") && instance.per_unit_storage_throughput
              if instance.storage_type == "SSD"
                valid_throughputs = [50, 100, 200, 500, 1000]
                unless valid_throughputs.include?(instance.per_unit_storage_throughput)
                  raise Dry::Struct::Error, "For PERSISTENT SSD, throughput must be one of: #{valid_throughputs.join(', ')} MB/s/TiB"
                end
              elsif instance.storage_type == "HDD"
                valid_throughputs = [12, 40]
                unless valid_throughputs.include?(instance.per_unit_storage_throughput)
                  raise Dry::Struct::Error, "For PERSISTENT HDD, throughput must be one of: #{valid_throughputs.join(', ')} MB/s/TiB"
                end
              end
            end
            
            # Validate SCRATCH deployment constraints
            if instance.deployment_type.start_with?("SCRATCH") && instance.per_unit_storage_throughput
              raise Dry::Struct::Error, "per_unit_storage_throughput cannot be specified for SCRATCH deployment types"
            end
            
            # Validate backup settings only for PERSISTENT
            if instance.deployment_type.start_with?("SCRATCH")
              if instance.automatic_backup_retention_days
                raise Dry::Struct::Error, "automatic_backup_retention_days cannot be set for SCRATCH deployment types"
              end
              if instance.daily_automatic_backup_start_time
                raise Dry::Struct::Error, "daily_automatic_backup_start_time cannot be set for SCRATCH deployment types"
              end
            end
            
            # Validate drive cache only for HDD
            if instance.drive_cache_type && instance.storage_type != "HDD"
              raise Dry::Struct::Error, "drive_cache_type can only be specified for HDD storage type"
            end
            
            # Validate backup retention days
            if instance.automatic_backup_retention_days
              days = instance.automatic_backup_retention_days
              if days < 0 || days > 90
                raise Dry::Struct::Error, "automatic_backup_retention_days must be between 0 and 90"
              end
            end
            
            # Validate imported file chunk size
            if instance.imported_file_chunk_size
              chunk_size = instance.imported_file_chunk_size
              if chunk_size < 1 || chunk_size > 512000
                raise Dry::Struct::Error, "imported_file_chunk_size must be between 1 and 512000 MB"
              end
            end
            
            instance
          end
          
          # Computed properties
          def is_persistent?
            deployment_type.start_with?("PERSISTENT")
          end
          
          def is_scratch?
            deployment_type.start_with?("SCRATCH")
          end
          
          def supports_backups?
            is_persistent?
          end
          
          def supports_throughput_configuration?
            is_persistent?
          end
          
          def supports_drive_cache?
            storage_type == "HDD"
          end
          
          def estimated_baseline_throughput
            # Baseline throughput in MB/s
            case deployment_type
            when "SCRATCH_1"
              200 * (storage_capacity / 1200) # 200 MB/s per 1.2 TB
            when "SCRATCH_2"
              240 * (storage_capacity / 1200) # 240 MB/s per 1.2 TB
            when "PERSISTENT_1", "PERSISTENT_2"
              if per_unit_storage_throughput
                (per_unit_storage_throughput * storage_capacity) / 1024 # Convert from MB/s/TiB to MB/s
              else
                # Default throughput if not specified
                if storage_type == "SSD"
                  50 * (storage_capacity / 1024) # 50 MB/s/TiB default
                else
                  12 * (storage_capacity / 1024) # 12 MB/s/TiB default
                end
              end
            end
          end
          
          def estimated_monthly_cost
            # Rough cost estimation in USD per month (as of 2024)
            storage_cost = case [storage_type, deployment_type]
            when ["SSD", "SCRATCH_2"]
              storage_capacity * 0.140 # $0.140/GB-month
            when ["HDD", "PERSISTENT_1"], ["HDD", "PERSISTENT_2"]
              storage_capacity * 0.015 # $0.015/GB-month
            when ["SSD", "PERSISTENT_1"], ["SSD", "PERSISTENT_2"]
              storage_capacity * 0.145 # $0.145/GB-month
            else
              storage_capacity * 0.140 # Default
            end
            
            # Add throughput cost for PERSISTENT
            throughput_cost = 0
            if is_persistent? && per_unit_storage_throughput && storage_type == "SSD"
              # Additional cost for higher throughput tiers
              throughput_multiplier = case per_unit_storage_throughput
              when 50 then 0 # Base tier included
              when 100 then 0.035
              when 200 then 0.070
              when 500 then 0.175
              when 1000 then 0.350
              else 0
              end
              throughput_cost = (storage_capacity / 1024.0) * throughput_multiplier * 730 # Monthly hours
            end
            
            { storage: storage_cost.round(2), throughput: throughput_cost.round(2), total: (storage_cost + throughput_cost).round(2) }
          end
        end
      end
    end
  end
end