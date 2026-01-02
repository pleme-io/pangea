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
require_relative 'types/helpers'

module Pangea
  module Resources
    module AWS
      module Types
        # FSx Lustre file system resource attributes with validation
        class FsxLustreFileSystemAttributes < Dry::Struct
          include FsxLustreHelpers
          transform_keys(&:to_sym)

          attribute? :import_path, Resources::Types::String.optional
          attribute? :export_path, Resources::Types::String.optional
          attribute :storage_capacity, Resources::Types::Integer
          attribute :subnet_ids, Resources::Types::Array.of(Resources::Types::String)
          attribute? :security_group_ids, Resources::Types::Array.of(Resources::Types::String).optional
          attribute :storage_type, Resources::Types::String.default('SSD').constrained(included_in: %w[SSD HDD])
          attribute? :per_unit_storage_throughput, Resources::Types::Integer.optional
          attribute :deployment_type, Resources::Types::String.default('SCRATCH_2').constrained(included_in: %w[SCRATCH_1 SCRATCH_2 PERSISTENT_1 PERSISTENT_2])
          attribute? :auto_import_policy, Resources::Types::String.optional.constrained(included_in: %w[NONE NEW NEW_CHANGED NEW_CHANGED_DELETED])
          attribute? :imported_file_chunk_size, Resources::Types::Integer.optional
          attribute? :weekly_maintenance_start_time, Resources::Types::String.optional
          attribute? :automatic_backup_retention_days, Resources::Types::Integer.optional
          attribute? :daily_automatic_backup_start_time, Resources::Types::String.optional
          attribute? :copy_tags_to_backups, Resources::Types::Bool.default(false)
          attribute? :data_compression_type, Resources::Types::String.default('NONE').constrained(included_in: %w[NONE LZ4])
          attribute? :drive_cache_type, Resources::Types::String.optional.constrained(included_in: %w[NONE READ])
          attribute? :kms_key_id, Resources::Types::String.optional
          attribute? :file_system_type_version, Resources::Types::String.default('2.15')
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            instance = super(attrs)
            validate_storage_capacity(instance)
            validate_throughput(instance)
            validate_scratch_constraints(instance)
            validate_hdd_constraints(instance)
            validate_backup_retention(instance)
            validate_chunk_size(instance)
            instance
          end

          def self.validate_storage_capacity(instance)
            if instance.storage_type == 'SSD'
              valid = [1200, 2400, 4800, 9600, 19200, 28800, 38400, 57600, 76800, 96000, 115200]
              raise Dry::Struct::Error, "For SSD storage, capacity must be one of: #{valid.join(', ')} GB" unless valid.include?(instance.storage_capacity)
            elsif instance.storage_type == 'HDD'
              if instance.storage_capacity < 6000 || instance.storage_capacity % 6000 != 0
                raise Dry::Struct::Error, 'For HDD storage, capacity must be a multiple of 6000 GB (minimum 6000 GB)'
              end
            end
          end

          def self.validate_throughput(instance)
            return unless instance.deployment_type.start_with?('PERSISTENT') && instance.per_unit_storage_throughput

            if instance.storage_type == 'SSD'
              valid = [50, 100, 200, 500, 1000]
              raise Dry::Struct::Error, "For PERSISTENT SSD, throughput must be one of: #{valid.join(', ')} MB/s/TiB" unless valid.include?(instance.per_unit_storage_throughput)
            elsif instance.storage_type == 'HDD'
              valid = [12, 40]
              raise Dry::Struct::Error, "For PERSISTENT HDD, throughput must be one of: #{valid.join(', ')} MB/s/TiB" unless valid.include?(instance.per_unit_storage_throughput)
            end
          end

          def self.validate_scratch_constraints(instance)
            return unless instance.deployment_type.start_with?('SCRATCH')

            raise Dry::Struct::Error, 'per_unit_storage_throughput cannot be specified for SCRATCH deployment types' if instance.per_unit_storage_throughput
            raise Dry::Struct::Error, 'automatic_backup_retention_days cannot be set for SCRATCH deployment types' if instance.automatic_backup_retention_days
            raise Dry::Struct::Error, 'daily_automatic_backup_start_time cannot be set for SCRATCH deployment types' if instance.daily_automatic_backup_start_time
          end

          def self.validate_hdd_constraints(instance)
            return unless instance.drive_cache_type && instance.storage_type != 'HDD'

            raise Dry::Struct::Error, 'drive_cache_type can only be specified for HDD storage type'
          end

          def self.validate_backup_retention(instance)
            return unless instance.automatic_backup_retention_days

            days = instance.automatic_backup_retention_days
            raise Dry::Struct::Error, 'automatic_backup_retention_days must be between 0 and 90' if days < 0 || days > 90
          end

          def self.validate_chunk_size(instance)
            return unless instance.imported_file_chunk_size

            chunk = instance.imported_file_chunk_size
            raise Dry::Struct::Error, 'imported_file_chunk_size must be between 1 and 512000 MB' if chunk < 1 || chunk > 512_000
          end
        end
      end
    end
  end
end
