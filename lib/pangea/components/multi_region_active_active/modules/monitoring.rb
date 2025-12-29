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
    module MultiRegionActiveActive
      # Regional monitoring and global dashboard resources
      module Monitoring
        def create_regional_monitoring(name, region_config, attrs, region_resources, tags)
          m = { log_group: aws_cloudwatch_log_group(component_resource_name(name, :log_group, region_config.region.to_sym),
                                                    { name: "/aws/multi-region/#{name}/#{region_config.region}",
                                                      retention_in_days: 30, tags: tags.merge(Region: region_config.region) }) }
          create_app_alarms(name, region_config, region_resources, m, tags) if region_resources[:application]
          create_canary(name, region_config, region_resources, m, tags) if attrs.monitoring.synthetic_monitoring
          m
        end

        def create_global_dashboard(name, attrs, resources, _tags)
          widgets = [build_overview_widget(attrs)]
          attrs.regions.each_with_index { |r, i| widgets << build_region_widget(r, resources, (i % 3) * 8, 8 + (i / 3) * 6) }
          widgets << build_traffic_widget(attrs, resources)
          widgets << build_replication_widget(attrs, resources) if attrs.global_database.engine.start_with?('aurora')
          aws_cloudwatch_dashboard(component_resource_name(name, :global_dashboard),
                                   { dashboard_name: "#{name}-global-overview",
                                     dashboard_body: JSON.generate({ widgets: widgets, periodOverride: 'auto', start: '-PT6H' }) })
        end

        private

        def create_app_alarms(name, region_config, region_resources, m, tags)
          app = region_resources[:application]
          m[:alb_health_alarm] = aws_cloudwatch_metric_alarm(
            component_resource_name(name, :alarm_alb_health, region_config.region.to_sym),
            { alarm_name: "#{name}-#{region_config.region}-alb-health", comparison_operator: 'LessThanThreshold',
              evaluation_periods: '2', metric_name: 'HealthyHostCount', namespace: 'AWS/ApplicationELB',
              period: '60', statistic: 'Minimum', threshold: '1',
              alarm_description: "ALB has unhealthy targets in #{region_config.region}",
              dimensions: { TargetGroup: app[:target_group].arn_suffix, LoadBalancer: app[:load_balancer].arn_suffix },
              tags: tags.merge(Region: region_config.region) })
          m[:ecs_health_alarm] = aws_cloudwatch_metric_alarm(
            component_resource_name(name, :alarm_ecs_health, region_config.region.to_sym),
            { alarm_name: "#{name}-#{region_config.region}-ecs-health", comparison_operator: 'LessThanThreshold',
              evaluation_periods: '2', metric_name: 'RunningTaskCount', namespace: 'AWS/ECS',
              period: '60', statistic: 'Average', threshold: '1',
              alarm_description: "ECS service has insufficient tasks in #{region_config.region}",
              dimensions: { ServiceName: app[:ecs_service].name, ClusterName: app[:ecs_cluster].name },
              tags: tags.merge(Region: region_config.region) })
        end

        def create_canary(name, region_config, region_resources, m, tags)
          private_subnets = region_resources[:subnets].select { |k, _| k.to_s.start_with?('private_') }.values.map(&:id)
          m[:canary] = aws_synthetics_canary(component_resource_name(name, :canary, region_config.region.to_sym),
                                             { name: "#{name}-#{region_config.region}-canary",
                                               artifact_s3_location: "s3://#{name}-canary-artifacts-#{region_config.region}/",
                                               execution_role_arn: 'arn:aws:iam::ACCOUNT:role/CloudWatchSyntheticsRole',
                                               handler: 'pageLoadBlueprint.handler', runtime_version: 'syn-nodejs-puppeteer-3.5',
                                               schedule: { expression: 'rate(5 minutes)' },
                                               run_config: { timeout_in_seconds: 300, memory_in_mb: 960, active_tracing: true },
                                               vpc_config: { subnet_ids: private_subnets,
                                                             security_group_ids: [region_resources[:application][:security_group].id] },
                                               tags: tags.merge(Region: region_config.region) })
        end

        def build_overview_widget(attrs)
          { type: 'metric', x: 0, y: 0, width: 24, height: 8,
            properties: { title: 'Global Infrastructure Overview', metrics: [], view: 'singleValue', region: 'us-east-1',
                          annotations: { horizontal: [{ label: 'All Regions Healthy', value: attrs.regions.length }] } } }
        end

        def build_region_widget(region, resources, x, y)
          r = resources[:regional][region.region.to_sym]
          { type: 'metric', x: x, y: y, width: 8, height: 6,
            properties: { title: "#{region.region} Health",
                          metrics: [['AWS/Route53', 'HealthCheckStatus', { HealthCheckId: r[:health_check]&.id }],
                                    ['AWS/ApplicationELB', 'HealthyHostCount',
                                     { TargetGroup: r[:application]&.dig(:target_group)&.arn_suffix,
                                       LoadBalancer: r[:application]&.dig(:load_balancer)&.arn_suffix }]].compact,
                          period: 300, stat: 'Average', region: region.region, yAxis: { left: { min: 0, max: 1 } } } }
        end

        def build_traffic_widget(attrs, resources)
          { type: 'metric', x: 0, y: 20, width: 12, height: 6,
            properties: { title: 'Global Traffic Distribution',
                          metrics: attrs.regions.map { |r| ['AWS/ApplicationELB', 'RequestCount',
                                                            { LoadBalancer: resources[:regional][r.region.to_sym][:application]&.dig(:load_balancer)&.arn_suffix }] }.compact,
                          period: 300, stat: 'Sum', region: 'us-east-1', stacked: true } }
        end

        def build_replication_widget(attrs, resources)
          { type: 'metric', x: 12, y: 20, width: 12, height: 6,
            properties: { title: 'Cross-Region Replication Lag',
                          metrics: attrs.regions.map { |r| ['AWS/RDS', 'AuroraReplicaLag',
                                                            { DBClusterIdentifier: resources[:regional][r.region.to_sym][:regional_cluster]&.dig(:cluster)&.id }] }.compact,
                          period: 300, stat: 'Average', region: 'us-east-1', yAxis: { left: { label: 'Milliseconds' } } } }
        end
      end
    end
  end
end
