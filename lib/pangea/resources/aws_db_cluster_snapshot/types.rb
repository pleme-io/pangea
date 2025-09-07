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
      # Type-safe attributes for AWS DB Cluster Snapshot resources
      class DbClusterSnapshotAttributes < Dry::Struct
        # DB cluster identifier to create snapshot from
        attribute :db_cluster_identifier, Resources::Types::String

        # Cluster snapshot identifier (unique within AWS account and region)
        attribute :db_cluster_snapshot_identifier, Resources::Types::String

        # Tags to apply to the cluster snapshot
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate cluster snapshot identifier format
          unless attrs.db_cluster_snapshot_identifier.match?(/^[a-zA-Z][a-zA-Z0-9-]*$/)
            raise Dry::Struct::Error, "db_cluster_snapshot_identifier must start with a letter and contain only letters, numbers, and hyphens"
          end

          # Validate cluster snapshot identifier length
          if attrs.db_cluster_snapshot_identifier.length > 255
            raise Dry::Struct::Error, "db_cluster_snapshot_identifier cannot exceed 255 characters"
          end

          attrs
        end

        # Generate unique cluster snapshot identifier with timestamp
        def self.timestamped_identifier(base_name)
          timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
          "#{base_name}-cluster-#{timestamp}"
        end

        # Check if snapshot follows naming convention
        def follows_naming_convention?
          db_cluster_snapshot_identifier.match?(/^[a-z]+-cluster-\d{8}-\d{6}$/)
        end

        # Extract base name from snapshot identifier
        def base_name
          return nil unless follows_naming_convention?
          parts = db_cluster_snapshot_identifier.split('-')
          return nil unless parts.include?('cluster')
          
          cluster_index = parts.index('cluster')
          return nil if cluster_index <= 0
          
          parts[0..cluster_index-1].join('-')
        end

        # Extract timestamp from snapshot identifier  
        def timestamp
          return nil unless follows_naming_convention?
          parts = db_cluster_snapshot_identifier.split('-')
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

        # Check if this is a global cluster snapshot
        def is_global_cluster_snapshot?
          db_cluster_identifier.include?('global') || 
          tags.any? { |k, v| k.to_s.downcase.include?('global') || v.to_s.downcase.include?('global') }
        end

        # Check if this is an Aurora cluster snapshot
        def is_aurora_snapshot?
          # Aurora clusters typically have aurora in the name or tags
          db_cluster_identifier.include?('aurora') ||
          tags.any? { |k, v| k.to_s.downcase.include?('aurora') || v.to_s.downcase.include?('aurora') }
        end

        # Generate summary
        def snapshot_summary
          summary = ["Source cluster: #{db_cluster_identifier}"]
          summary << "Age: #{age_in_days} days" if age_in_days
          summary << "Type: #{is_aurora_snapshot? ? 'Aurora' : 'RDS'} cluster"
          summary << "Global: yes" if is_global_cluster_snapshot?
          summary << "Convention: #{follows_naming_convention? ? 'compliant' : 'custom'}"
          summary.join("; ")
        end

        # Estimate storage cost (cluster snapshots typically larger than instance snapshots)
        def estimated_monthly_storage_cost
          "$0.095 per GB/month (cluster snapshots may be larger than instance snapshots)"
        end

        # Get snapshot retention recommendation based on purpose
        def recommended_retention_days
          case tags[:Purpose]&.to_s&.downcase
          when "backup"
            30
          when "migration", "pre-maintenance"
            7
          when "development", "testing"
            3
          else
            14 # Default
          end
        end
      end

      # Common DB Cluster Snapshot configurations
      module DbClusterSnapshotConfigs
        # Production Aurora cluster backup
        def self.aurora_production_backup(cluster_id:, snapshot_id: nil)
          {
            db_cluster_identifier: cluster_id,
            db_cluster_snapshot_identifier: snapshot_id || DbClusterSnapshotAttributes.timestamped_identifier("#{cluster_id}-prod-backup"),
            tags: {
              Purpose: "backup",
              Environment: "production",
              Engine: "aurora",
              Automated: "false",
              Type: "manual",
              RetentionDays: "30"
            }
          }
        end

        # Global cluster snapshot
        def self.global_cluster_backup(cluster_id:, region:, snapshot_id: nil)
          {
            db_cluster_identifier: cluster_id,
            db_cluster_snapshot_identifier: snapshot_id || DbClusterSnapshotAttributes.timestamped_identifier("#{cluster_id}-global-#{region}"),
            tags: {
              Purpose: "global-backup",
              Region: region,
              Type: "global-cluster",
              Automated: "false",
              CrossRegion: "true"
            }
          }
        end

        # Pre-upgrade snapshot
        def self.pre_upgrade_snapshot(cluster_id:, from_version:, to_version:)
          {
            db_cluster_identifier: cluster_id,
            db_cluster_snapshot_identifier: DbClusterSnapshotAttributes.timestamped_identifier("#{cluster_id}-pre-upgrade"),
            tags: {
              Purpose: "pre-upgrade",
              FromVersion: from_version,
              ToVersion: to_version,
              Type: "safety",
              Critical: "true",
              RetentionDays: "14"
            }
          }
        end

        # Development cluster snapshot
        def self.development_snapshot(cluster_id:, purpose: "testing")
          {
            db_cluster_identifier: cluster_id,
            db_cluster_snapshot_identifier: DbClusterSnapshotAttributes.timestamped_identifier("#{cluster_id}-dev-#{purpose}"),
            tags: {
              Purpose: purpose,
              Environment: "development",
              Temporary: "true",
              Type: "manual",
              RetentionDays: "3"
            }
          }
        end

        # Disaster recovery snapshot
        def self.disaster_recovery_snapshot(cluster_id:, primary_region:, dr_region:)
          {
            db_cluster_identifier: cluster_id,
            db_cluster_snapshot_identifier: DbClusterSnapshotAttributes.timestamped_identifier("#{cluster_id}-dr-#{dr_region}"),
            tags: {
              Purpose: "disaster-recovery",
              PrimaryRegion: primary_region,
              DRRegion: dr_region,
              Type: "cross-region",
              Critical: "true",
              RetentionDays: "90"
            }
          }
        end

        # Point-in-time recovery preparation snapshot
        def self.pitr_baseline(cluster_id:, restore_point:)
          {
            db_cluster_identifier: cluster_id,
            db_cluster_snapshot_identifier: DbClusterSnapshotAttributes.timestamped_identifier("#{cluster_id}-pitr-baseline"),
            tags: {
              Purpose: "pitr-baseline",
              RestorePoint: restore_point,
              Type: "recovery",
              Baseline: "true"
            }
          }
        end
      end
    end
      end
    end
  end
end