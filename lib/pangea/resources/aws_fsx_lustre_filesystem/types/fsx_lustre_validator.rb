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

module Pangea
  module Resources
    module AWS
      module Types
        # Validation logic for FSx Lustre file system attributes
        module FsxLustreValidator
          SSD_VALID_CAPACITIES = [1200, 2400, 4800, 9600, 19200, 28800, 38400, 57600, 76800, 96000, 115200].freeze
          SSD_THROUGHPUTS = [50, 100, 200, 500, 1000].freeze
          HDD_THROUGHPUTS = [12, 40].freeze

          def validate_storage_capacity
            if storage_type == "SSD"
              unless SSD_VALID_CAPACITIES.include?(storage_capacity)
                raise Dry::Struct::Error, "For SSD storage, capacity must be one of: #{SSD_VALID_CAPACITIES.join(', ')} GB"
              end
            elsif storage_type == "HDD"
              if storage_capacity < 6000 || storage_capacity % 6000 != 0
                raise Dry::Struct::Error, "For HDD storage, capacity must be a multiple of 6000 GB (minimum 6000 GB)"
              end
            end
          end

          def validate_throughput
            return unless deployment_type.start_with?("PERSISTENT") && per_unit_storage_throughput

            if storage_type == "SSD"
              unless SSD_THROUGHPUTS.include?(per_unit_storage_throughput)
                raise Dry::Struct::Error, "For PERSISTENT SSD, throughput must be one of: #{SSD_THROUGHPUTS.join(', ')} MB/s/TiB"
              end
            elsif storage_type == "HDD"
              unless HDD_THROUGHPUTS.include?(per_unit_storage_throughput)
                raise Dry::Struct::Error, "For PERSISTENT HDD, throughput must be one of: #{HDD_THROUGHPUTS.join(', ')} MB/s/TiB"
              end
            end
          end

          def validate_scratch_constraints
            return unless deployment_type.start_with?("SCRATCH")

            if per_unit_storage_throughput
              raise Dry::Struct::Error, "per_unit_storage_throughput cannot be specified for SCRATCH deployment types"
            end
            if automatic_backup_retention_days
              raise Dry::Struct::Error, "automatic_backup_retention_days cannot be set for SCRATCH deployment types"
            end
            if daily_automatic_backup_start_time
              raise Dry::Struct::Error, "daily_automatic_backup_start_time cannot be set for SCRATCH deployment types"
            end
          end

          def validate_drive_cache
            if drive_cache_type && storage_type != "HDD"
              raise Dry::Struct::Error, "drive_cache_type can only be specified for HDD storage type"
            end
          end

          def validate_backup_retention
            return unless automatic_backup_retention_days

            days = automatic_backup_retention_days
            if days < 0 || days > 90
              raise Dry::Struct::Error, "automatic_backup_retention_days must be between 0 and 90"
            end
          end

          def validate_chunk_size
            return unless imported_file_chunk_size

            chunk_size = imported_file_chunk_size
            if chunk_size < 1 || chunk_size > 512000
              raise Dry::Struct::Error, "imported_file_chunk_size must be between 1 and 512000 MB"
            end
          end

          def run_validations
            validate_storage_capacity
            validate_throughput
            validate_scratch_constraints
            validate_drive_cache
            validate_backup_retention
            validate_chunk_size
          end
        end
      end
    end
  end
end
