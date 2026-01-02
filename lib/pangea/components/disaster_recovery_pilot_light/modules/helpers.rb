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
    module DisasterRecoveryPilotLight
      # Shared helper methods for DR Pilot Light component
      module Helpers
        def extract_pilot_light_resources(dr_resources)
          resources = []

          resources << "VPC and Subnets" if dr_resources[:vpc]
          resources << "Launch Template" if dr_resources[:launch_template]
          resources << "Auto Scaling Group (scaled to 0)" if dr_resources[:asg]
          resources << "Database Subnet Group" if dr_resources[:db_subnet_group]
          resources << "Database Read Replicas" if dr_resources[:database_replicas]

          resources
        end

        def calculate_readiness_score(attrs, resources)
          score = 0.0

          # Data replication (30 points)
          score += 10.0 if resources[:replication][:database_replicas]&.any?
          score += 10.0 if resources[:replication][:s3_replication]&.any?
          score += 10.0 if resources[:replication][:efs_replication]&.any?

          # Backup infrastructure (20 points)
          score += 10.0 if resources[:backup][:backup_vault]
          score += 10.0 if attrs.critical_data.cross_region_backup

          # Activation automation (20 points)
          score += 10.0 if resources[:activation][:state_machine]
          score += 10.0 if resources[:activation][:runbook]

          # Testing (15 points)
          score += 10.0 if attrs.testing.automated_testing
          score += 5.0 if attrs.testing.test_scenarios.length >= 2

          # Monitoring (15 points)
          score += 7.5 if attrs.monitoring.dashboard_enabled
          score += 7.5 if attrs.monitoring.alerting_enabled

          score.round(1)
        end

        def estimate_dr_cost(attrs, resources)
          cost = 0.0

          # Database read replicas
          if attrs.pilot_light.database_replicas
            replica_count = attrs.critical_data.databases.length
            cost += replica_count * 50.0  # Minimal instance size
          end

          # S3 replication storage
          if attrs.critical_data.s3_buckets.any?
            cost += 1000 * 0.0125  # S3 IA storage
            cost += 100 * 0.01     # Replication data transfer
          end

          # EFS replication
          if attrs.critical_data.efs_filesystems.any?
            cost += attrs.critical_data.efs_filesystems.length * 30.0
          end

          # Backup costs
          cost += 0.05 * 1000  # 1TB backup storage estimate

          # DMS instance (if needed)
          cost += 50.0 if resources[:replication][:dms_instance]

          # Monitoring and automation
          cost += 10.0  # CloudWatch dashboards and alarms
          cost += 5.0   # Lambda executions

          # Testing costs (periodic)
          if attrs.testing.automated_testing
            cost += 4 * 10.0  # 4 tests per month, 1 hour each
          end

          cost.round(2)
        end

        def build_outputs(name, attrs, resources)
          {
            dr_name: attrs.dr_name,
            primary_region: attrs.primary_region.region,
            dr_region: attrs.dr_region.region,
            rto_hours: attrs.compliance.rto_hours,
            rpo_hours: attrs.compliance.rpo_hours,
            pilot_light_resources: extract_pilot_light_resources(resources[:dr]),
            activation_method: attrs.activation.activation_method,
            activation_runbook_url: resources.dig(:activation, :runbook, :url),
            data_replication_status: build_replication_status(resources),
            backup_status: build_backup_status(attrs, resources),
            testing_configuration: build_testing_config(attrs),
            cost_optimization_features: build_cost_features(attrs),
            monitoring_dashboards: extract_dashboard_names(resources),
            estimated_monthly_cost: estimate_dr_cost(attrs, resources),
            readiness_score: calculate_readiness_score(attrs, resources)
          }
        end

        private

        def build_replication_status(resources)
          {
            databases: resources[:replication][:database_replicas]&.any? ? "Active" : "Not configured",
            s3_buckets: resources[:replication][:s3_replication]&.any? ? "Active" : "Not configured",
            efs_filesystems: resources[:replication][:efs_replication]&.any? ? "Active" : "Not configured"
          }
        end

        def build_backup_status(attrs, resources)
          {
            vault_name: resources[:backup][:backup_vault]&.name,
            plan_name: resources[:backup][:backup_plan]&.name,
            cross_region_enabled: attrs.critical_data.cross_region_backup
          }
        end

        def build_testing_config(attrs)
          {
            automated: attrs.testing.automated_testing,
            schedule: attrs.testing.test_schedule,
            scenarios: attrs.testing.test_scenarios
          }
        end

        def build_cost_features(attrs)
          [
            ("Spot Instances" if attrs.cost_optimization.use_spot_instances),
            ("Auto-shutdown Non-critical" if attrs.cost_optimization.auto_shutdown_non_critical),
            ("Compressed Backups" if attrs.cost_optimization.compress_backups),
            ("Data Deduplication" if attrs.cost_optimization.dedup_enabled),
            ("Lifecycle Policies" if attrs.cost_optimization.data_lifecycle_policies)
          ].compact
        end

        def extract_dashboard_names(resources)
          [
            resources.dig(:monitoring, :primary_dashboard)&.dashboard_name,
            resources.dig(:monitoring, :dr_dashboard)&.dashboard_name,
            resources.dig(:monitoring, :replication_dashboard)&.dashboard_name
          ].compact
        end
      end
    end
  end
end
