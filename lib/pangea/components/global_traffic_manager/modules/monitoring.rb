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
    module GlobalTrafficManager
      # Monitoring stack resources
      module Monitoring
        def create_monitoring_resources(name, attrs, resources, tags)
          return unless attrs.observability.cloudwatch_enabled

          monitoring_resources = {}
          create_dashboard(name, attrs, resources, monitoring_resources)
          create_alarms(name, attrs, resources, tags, monitoring_resources) if attrs.observability.alerting_enabled
          resources[:monitoring] = monitoring_resources
        end

        private

        def create_dashboard(name, attrs, resources, monitoring_resources)
          widgets = build_dashboard_widgets(attrs, resources)

          dashboard_ref = aws_cloudwatch_dashboard(
            component_resource_name(name, :dashboard),
            {
              dashboard_name: "#{name}-global-traffic",
              dashboard_body: JSON.generate({
                widgets: widgets,
                periodOverride: 'auto',
                start: '-PT6H'
              })
            }
          )
          monitoring_resources[:dashboard] = dashboard_ref
        end

        def build_dashboard_widgets(attrs, resources)
          widgets = []
          widgets << ga_traffic_widget(resources) if attrs.enable_global_accelerator
          widgets << cloudfront_performance_widget(resources) if attrs.cloudfront.enabled
          widgets << endpoint_health_widget(attrs, resources)
          widgets << traffic_distribution_widget
          widgets
        end

        def ga_traffic_widget(resources)
          {
            type: 'metric', x: 0, y: 0, width: 12, height: 6,
            properties: {
              title: 'Global Accelerator Traffic',
              metrics: [
                ['AWS/GlobalAccelerator', 'NewFlowCount', { AcceleratorArn: resources[:global_accelerator][:accelerator].arn }],
                ['.', 'ProcessedBytesIn', { AcceleratorArn: resources[:global_accelerator][:accelerator].arn }],
                ['.', 'ProcessedBytesOut', { AcceleratorArn: resources[:global_accelerator][:accelerator].arn }]
              ],
              period: 300, stat: 'Sum', region: 'us-west-2',
              yAxis: { left: { label: 'Count/Bytes' } }
            }
          }
        end

        def cloudfront_performance_widget(resources)
          {
            type: 'metric', x: 12, y: 0, width: 12, height: 6,
            properties: {
              title: 'CloudFront Performance',
              metrics: [
                ['AWS/CloudFront', 'Requests', { DistributionId: resources[:cloudfront][:distribution].id }],
                ['.', 'BytesDownloaded', { DistributionId: resources[:cloudfront][:distribution].id }],
                ['.', 'OriginLatency', { DistributionId: resources[:cloudfront][:distribution].id }, { stat: 'Average' }]
              ],
              period: 300, stat: 'Sum', region: 'us-east-1'
            }
          }
        end

        def endpoint_health_widget(attrs, resources)
          health_metrics = attrs.endpoints.filter_map do |endpoint|
            health_check = resources[:health_checks][endpoint.region.to_sym]
            next unless health_check

            ['AWS/Route53', 'HealthCheckStatus', { HealthCheckId: health_check.id }]
          end

          {
            type: 'metric', x: 0, y: 6, width: 24, height: 6,
            properties: {
              title: 'Endpoint Health Status',
              metrics: health_metrics,
              period: 60, stat: 'Average', region: 'us-east-1',
              yAxis: { left: { min: 0, max: 1 } },
              annotations: {
                horizontal: [
                  { label: 'Healthy', value: 1, fill: 'above' },
                  { label: 'Unhealthy', value: 0, fill: 'below' }
                ]
              }
            }
          }
        end

        def traffic_distribution_widget
          {
            type: 'metric', x: 0, y: 12, width: 12, height: 6,
            properties: {
              title: 'Traffic Distribution by Region',
              metrics: [],
              period: 300, stat: 'Sum', region: 'us-east-1', stacked: true
            }
          }
        end

        def create_alarms(name, attrs, resources, tags, monitoring_resources)
          create_ga_alarm(name, resources, tags, monitoring_resources) if attrs.enable_global_accelerator
          create_endpoint_health_alarms(name, attrs, resources, tags, monitoring_resources)
        end

        def create_ga_alarm(name, resources, tags, monitoring_resources)
          ga_alarm_ref = aws_cloudwatch_metric_alarm(
            component_resource_name(name, :alarm_ga_flows),
            {
              alarm_name: "#{name}-ga-high-flow-count",
              comparison_operator: 'GreaterThanThreshold',
              evaluation_periods: '2',
              metric_name: 'NewFlowCount',
              namespace: 'AWS/GlobalAccelerator',
              period: '300',
              statistic: 'Sum',
              threshold: '10000',
              alarm_description: 'High number of new flows to Global Accelerator',
              dimensions: { AcceleratorArn: resources[:global_accelerator][:accelerator].arn },
              tags: tags
            }
          )
          monitoring_resources[:ga_alarm] = ga_alarm_ref
        end

        def create_endpoint_health_alarms(name, attrs, resources, tags, monitoring_resources)
          attrs.endpoints.each do |endpoint|
            health_check = resources[:health_checks][endpoint.region.to_sym]
            next unless health_check

            health_alarm_ref = aws_cloudwatch_metric_alarm(
              component_resource_name(name, :alarm_health, endpoint.region.to_sym),
              {
                alarm_name: "#{name}-#{endpoint.region}-unhealthy",
                comparison_operator: 'LessThanThreshold',
                evaluation_periods: '2',
                metric_name: 'HealthCheckStatus',
                namespace: 'AWS/Route53',
                period: '60',
                statistic: 'Minimum',
                threshold: '1',
                alarm_description: "Endpoint unhealthy in #{endpoint.region}",
                dimensions: { HealthCheckId: health_check.id },
                alarm_actions: attrs.observability.notification_topic_ref ? [attrs.observability.notification_topic_ref.arn] : nil,
                tags: tags.merge(Region: endpoint.region)
              }.compact
            )
            monitoring_resources["health_alarm_#{endpoint.region}".to_sym] = health_alarm_ref
          end
        end
      end
    end
  end
end
