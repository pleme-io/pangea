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
