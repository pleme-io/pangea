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
  module Components
    module MySqlDatabaseComponent
      # Helper methods for MySQL component
      module Helpers
        # Build component outputs hash
        def build_component_outputs(name, component_attrs, db_instance_ref, subnet_group_ref, parameter_group_ref, read_replicas)
          {
            db_instance_identifier: db_instance_ref.identifier,
            db_instance_arn: db_instance_ref.arn,
            db_instance_endpoint: db_instance_ref.endpoint,
            db_instance_hosted_zone_id: db_instance_ref.hosted_zone_id,
            db_instance_port: db_instance_ref.port,
            db_instance_status: db_instance_ref.status,
            db_subnet_group_name: subnet_group_ref.name,
            parameter_group_name: parameter_group_ref&.name,
            read_replica_identifiers: read_replicas.transform_values(&:identifier),
            security_features: build_security_features(component_attrs, parameter_group_ref),
            backup_retention_days: component_attrs.backup.backup_retention_period,
            maintenance_window: component_attrs.maintenance.maintenance_window,
            backup_window: component_attrs.backup.backup_window,
            multi_az_enabled: component_attrs.multi_az,
            storage_encrypted: component_attrs.storage_encrypted,
            estimated_monthly_cost: estimate_rds_monthly_cost(
              component_attrs.db_instance_class,
              component_attrs.allocated_storage,
              component_attrs.multi_az,
              component_attrs.create_read_replica ? component_attrs.read_replica_count : 0
            )
          }
        end

        # Estimate monthly cost for RDS instance
        def estimate_rds_monthly_cost(instance_class, storage_gb, multi_az, read_replica_count)
          base_cost = calculate_base_cost(instance_class)

          # Multi-AZ doubles the instance cost
          instance_cost = multi_az ? base_cost * 2 : base_cost

          # Storage cost (approximate)
          storage_cost = storage_gb * 0.115 # GP3 pricing

          # Read replica cost
          replica_cost = read_replica_count * base_cost

          # Backup storage (estimated as 20% of allocated storage)
          backup_cost = storage_gb * 0.2 * 0.095

          (instance_cost + storage_cost + replica_cost + backup_cost).round(2)
        end

        private

        def build_security_features(component_attrs, parameter_group_ref)
          [
            ("Encryption at Rest" if component_attrs.storage_encrypted),
            ("Multi-AZ Deployment" if component_attrs.multi_az),
            ("Automated Backups" if component_attrs.backup.backup_retention_period > 0),
            ("Performance Insights" if component_attrs.monitoring.performance_insights_enabled),
            ("Enhanced Monitoring" if component_attrs.monitoring.monitoring_interval > 0),
            ("Deletion Protection" if component_attrs.deletion_protection),
            ("Private Deployment" if !component_attrs.publicly_accessible),
            ("CloudWatch Logs" if component_attrs.enabled_cloudwatch_logs_exports.any?),
            ("Parameter Group Optimization" if parameter_group_ref),
            ("Read Replicas" if component_attrs.create_read_replica)
          ].compact
        end

        def calculate_base_cost(instance_class)
          case instance_class
          when /^db\.t3\.micro$/
            15.0
          when /^db\.t3\.small$/
            30.0
          when /^db\.t3\.medium$/
            60.0
          when /^db\.t3\.large$/
            120.0
          when /^db\.r5\.large$/
            150.0
          when /^db\.m5\.large$/
            140.0
          else
            75.0 # Default estimate
          end
        end
      end
    end
  end
end
