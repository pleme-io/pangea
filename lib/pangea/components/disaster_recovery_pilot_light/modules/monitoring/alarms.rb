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
      module Monitoring
        # CloudWatch alarms for DR monitoring
        module Alarms
          def create_alerting_resources(name, attrs, resources, monitoring_resources, tags)
            if resources[:replication][:database_replicas]&.any?
              monitoring_resources[:lag_alarm] = create_replication_lag_alarm(
                name, attrs, tags
              )
            end

            monitoring_resources[:backup_alarm] = create_backup_failure_alarm(
              name, resources, tags
            )
          end

          private

          def create_replication_lag_alarm(name, attrs, tags)
            threshold_ms = attrs.monitoring.replication_lag_threshold_seconds * 1000

            aws_cloudwatch_metric_alarm(
              component_resource_name(name, :replication_lag_alarm),
              {
                alarm_name: "#{name}-replication-lag-high",
                comparison_operator: "GreaterThanThreshold",
                evaluation_periods: "2",
                metric_name: "AuroraReplicaLag",
                namespace: "AWS/RDS",
                period: "300",
                statistic: "Average",
                threshold: threshold_ms.to_s,
                alarm_description: "Database replication lag is too high",
                dimensions: { DBClusterIdentifier: "#{name}-dr-cluster-*" },
                tags: tags
              }
            )
          end

          def create_backup_failure_alarm(name, resources, tags)
            aws_cloudwatch_metric_alarm(
              component_resource_name(name, :backup_failure_alarm),
              {
                alarm_name: "#{name}-backup-failures",
                comparison_operator: "GreaterThanThreshold",
                evaluation_periods: "1",
                metric_name: "NumberOfBackupJobsFailed",
                namespace: "AWS/Backup",
                period: "86400",
                statistic: "Sum",
                threshold: "0",
                alarm_description: "Backup jobs are failing",
                dimensions: { BackupVaultName: resources[:backup][:backup_vault].name },
                tags: tags
              }
            )
          end
        end
      end
    end
  end
end
