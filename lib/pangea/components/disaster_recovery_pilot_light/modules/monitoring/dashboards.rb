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

require 'json'

module Pangea
  module Components
    module DisasterRecoveryPilotLight
      module Monitoring
        # Dashboard creation for DR monitoring
        module Dashboards
          def create_region_dashboard(name, region_type, region_config, region_resources, tags)
            widgets = build_region_widgets(region_type, region_config, region_resources)

            aws_cloudwatch_dashboard(
              component_resource_name(name, :"#{region_type}_dashboard"),
              {
                dashboard_name: "#{name}-#{region_type}-region",
                dashboard_body: JSON.generate({
                  widgets: widgets,
                  periodOverride: "auto",
                  start: "-PT6H"
                })
              }
            )
          end

          def create_replication_dashboard(name, attrs, resources, tags)
            widgets = build_replication_widgets(name, attrs, resources)

            aws_cloudwatch_dashboard(
              component_resource_name(name, :replication_dashboard),
              {
                dashboard_name: "#{name}-replication-status",
                dashboard_body: JSON.generate({
                  widgets: widgets,
                  periodOverride: "auto",
                  start: "-PT24H"
                })
              }
            )
          end

          private

          def build_region_widgets(region_type, region_config, region_resources)
            [
              build_vpc_health_widget(region_type, region_config, region_resources),
              build_resources_widget(region_type, region_config)
            ]
          end

          def build_vpc_health_widget(region_type, region_config, region_resources)
            {
              type: "metric",
              x: 0, y: 0, width: 12, height: 6,
              properties: {
                title: "#{region_type.capitalize} Region VPC Health",
                metrics: [
                  ["AWS/EC2", "NetworkPacketsIn", { VPC: region_resources[:vpc].id }],
                  [".", "NetworkPacketsOut", { VPC: region_resources[:vpc].id }]
                ],
                period: 300,
                stat: "Sum",
                region: region_config.region
              }
            }
          end

          def build_resources_widget(region_type, region_config)
            {
              type: "metric",
              x: 12, y: 0, width: 12, height: 6,
              properties: {
                title: "#{region_type.capitalize} Region Resources",
                metrics: [],
                period: 300,
                stat: "Average",
                region: region_config.region,
                annotations: { horizontal: [{ label: "Healthy", value: 1 }] }
              }
            }
          end

          def build_replication_widgets(name, attrs, resources)
            widgets = []

            if resources[:replication][:database_replicas]&.any?
              widgets << build_db_replication_widget(name, attrs)
            end

            if resources[:replication][:s3_replication]&.any?
              widgets << build_s3_replication_widget(attrs)
            end

            widgets << build_backup_widget(attrs, resources)
            widgets
          end

          def build_db_replication_widget(name, attrs)
            {
              type: "metric",
              x: 0, y: 0, width: 12, height: 6,
              properties: {
                title: "Database Replication Lag",
                metrics: [
                  ["AWS/RDS", "AuroraReplicaLag", { DBClusterIdentifier: "#{name}-dr-cluster-*" }]
                ],
                period: 300,
                stat: "Average",
                region: attrs.dr_region.region,
                yAxis: { left: { label: "Milliseconds" } }
              }
            }
          end

          def build_s3_replication_widget(attrs)
            {
              type: "metric",
              x: 12, y: 0, width: 12, height: 6,
              properties: {
                title: "S3 Replication Status",
                metrics: [
                  ["AWS/S3", "ReplicationLatency", { SourceBucket: "*", DestinationBucket: "*-dr-*" }]
                ],
                period: 300,
                stat: "Average",
                region: attrs.primary_region.region
              }
            }
          end

          def build_backup_widget(attrs, resources)
            {
              type: "metric",
              x: 0, y: 6, width: 12, height: 6,
              properties: {
                title: "Backup Job Success Rate",
                metrics: [
                  ["AWS/Backup", "NumberOfBackupJobsCompleted",
                   { BackupVaultName: resources[:backup][:backup_vault].name }],
                  [".", "NumberOfBackupJobsFailed",
                   { BackupVaultName: resources[:backup][:backup_vault].name }]
                ],
                period: 86_400,
                stat: "Sum",
                region: attrs.primary_region.region
              }
            }
          end
        end
      end
    end
  end
end
