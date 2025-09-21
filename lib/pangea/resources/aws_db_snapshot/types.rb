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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS DB Snapshot resources
      class DbSnapshotAttributes < Dry::Struct
        # DB instance identifier to create snapshot from
        attribute :db_instance_identifier, Resources::Types::String

        # Snapshot identifier (unique within AWS account and region)
        attribute :db_snapshot_identifier, Resources::Types::String

        # Tags to apply to the snapshot
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate snapshot identifier format
          unless attrs.db_snapshot_identifier.match?(/^[a-zA-Z][a-zA-Z0-9-]*$/)
            raise Dry::Struct::Error, "db_snapshot_identifier must start with a letter and contain only letters, numbers, and hyphens"
          end

          # Validate snapshot identifier length
          if attrs.db_snapshot_identifier.length > 255
            raise Dry::Struct::Error, "db_snapshot_identifier cannot exceed 255 characters"
          end

          attrs
        end

        # Generate unique snapshot identifier with timestamp
        def self.timestamped_identifier(base_name)
          timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
          "#{base_name}-#{timestamp}"
        end

        # Check if snapshot follows naming convention
        def follows_naming_convention?
          db_snapshot_identifier.match?(/^[a-z]+-[a-z]+-\d{8}-\d{6}$/)
        end

        # Extract base name from snapshot identifier
        def base_name
          return nil unless follows_naming_convention?
          parts = db_snapshot_identifier.split('-')
          parts[0..1].join('-') if parts.length >= 4
        end

        # Extract timestamp from snapshot identifier
        def timestamp
          return nil unless follows_naming_convention?
          parts = db_snapshot_identifier.split('-')
          return nil unless parts.length >= 4
          
          date_part = parts[-2]
          time_part = parts[-1]
          
          begin
            DateTime.strptime("#{date_part}#{time_part}", "%Y%m%d%H%M%S")
          rescue Date::Error
            nil
          end
        end

        # Get snapshot age in days
        def age_in_days
          ts = timestamp
          return nil unless ts
          (DateTime.now - ts).to_i
        end

        # Check if snapshot is older than specified days
        def older_than?(days)
          age = age_in_days
          return false unless age
          age > days
        end

        # Generate summary
        def snapshot_summary
          summary = ["Source: #{db_instance_identifier}"]
          summary << "Age: #{age_in_days} days" if age_in_days
          summary << "Convention: #{follows_naming_convention? ? 'compliant' : 'custom'}"
          summary.join("; ")
        end

        # Estimate storage cost (rough AWS pricing)
        def estimated_monthly_storage_cost
          "$0.095 per GB/month (actual cost depends on snapshot size)"
        end
      end

      # Common DB Snapshot configurations  
      module DbSnapshotConfigs
        # Production backup snapshot
        def self.production_backup(db_instance_id:, snapshot_id: nil)
          {
            db_instance_identifier: db_instance_id,
            db_snapshot_identifier: snapshot_id || DbSnapshotAttributes.timestamped_identifier("#{db_instance_id}-backup"),
            tags: { 
              Purpose: "backup", 
              Environment: "production",
              Automated: "false",
              Type: "manual"
            }
          }
        end

        # Pre-maintenance snapshot
        def self.pre_maintenance(db_instance_id:, maintenance_type:)
          {
            db_instance_identifier: db_instance_id,
            db_snapshot_identifier: DbSnapshotAttributes.timestamped_identifier("#{db_instance_id}-pre-#{maintenance_type}"),
            tags: {
              Purpose: "pre-maintenance",
              MaintenanceType: maintenance_type,
              Automated: "false",
              Type: "safety"
            }
          }
        end

        # Development snapshot for testing
        def self.development_snapshot(db_instance_id:, purpose: "testing")
          {
            db_instance_identifier: db_instance_id,
            db_snapshot_identifier: DbSnapshotAttributes.timestamped_identifier("#{db_instance_id}-#{purpose}"),
            tags: {
              Purpose: purpose,
              Environment: "development", 
              Temporary: "true",
              Type: "manual"
            }
          }
        end

        # Migration snapshot
        def self.migration_snapshot(db_instance_id:, migration_id:)
          {
            db_instance_identifier: db_instance_id,
            db_snapshot_identifier: "#{db_instance_id}-migration-#{migration_id}",
            tags: {
              Purpose: "migration",
              MigrationId: migration_id,
              Type: "safety",
              Critical: "true"
            }
          }
        end
      end
    end
      end
    end
  end
end