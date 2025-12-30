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
        # Common RDS Cluster Endpoint configurations
        module RdsClusterEndpointConfigs
          # Read-only endpoint for reporting and analytics
          def self.read_replica_endpoint(cluster_id:, endpoint_id: "read-replica")
            {
              cluster_identifier: cluster_id,
              cluster_endpoint_identifier: endpoint_id,
              custom_endpoint_type: "READER",
              tags: { Purpose: "read-replica", Usage: "analytics" }
            }
          end

          # Custom reader endpoint excluding specific instances
          def self.analytics_endpoint(cluster_id:, excluded_db_instances: [], endpoint_id: "analytics")
            excluded_members = excluded_db_instances.map { |db_id| { db_instance_identifier: db_id } }

            {
              cluster_identifier: cluster_id,
              cluster_endpoint_identifier: endpoint_id,
              custom_endpoint_type: "READER",
              excluded_members: excluded_members,
              tags: { Purpose: "analytics", Type: "custom-reader" }
            }
          end

          # Static reader endpoint with specific instances
          def self.dedicated_reader_endpoint(cluster_id:, static_db_instances:, endpoint_id: "dedicated-reader")
            static_members = static_db_instances.map { |db_id| { db_instance_identifier: db_id } }

            {
              cluster_identifier: cluster_id,
              cluster_endpoint_identifier: endpoint_id,
              custom_endpoint_type: "READER",
              static_members: static_members,
              tags: { Purpose: "dedicated-reader", Type: "static-members" }
            }
          end

          # Any endpoint for connection pooling
          def self.pooled_endpoint(cluster_id:, endpoint_id: "pooled")
            {
              cluster_identifier: cluster_id,
              cluster_endpoint_identifier: endpoint_id,
              custom_endpoint_type: "ANY",
              tags: { Purpose: "connection-pooling", Type: "any" }
            }
          end

          # Development/testing endpoint
          def self.development_endpoint(cluster_id:, endpoint_id: "dev")
            {
              cluster_identifier: cluster_id,
              cluster_endpoint_identifier: endpoint_id,
              custom_endpoint_type: "READER",
              tags: { Environment: "development", Purpose: "testing" }
            }
          end

          # Regional failover endpoint
          def self.failover_endpoint(cluster_id:, excluded_primary: nil, endpoint_id: "failover")
            config = {
              cluster_identifier: cluster_id,
              cluster_endpoint_identifier: endpoint_id,
              custom_endpoint_type: "READER",
              tags: { Purpose: "failover", Type: "disaster-recovery" }
            }

            if excluded_primary
              config[:excluded_members] = [{ db_instance_identifier: excluded_primary }]
            end

            config
          end
        end
      end
    end
  end
end
