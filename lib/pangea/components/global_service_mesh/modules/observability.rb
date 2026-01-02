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
    module GlobalServiceMesh
      # Observability infrastructure: X-Ray, CloudWatch, logging, and alarms
      module Observability
        def create_observability_infrastructure(name, attrs, _resources, tags)
          observability = {}
          create_xray_resources(name, attrs, tags, observability) if attrs.observability.xray_enabled
          observability[:log_groups] = create_log_groups(name, attrs, tags) if attrs.observability.access_logging_enabled
          observability[:dashboard] = create_dashboard(name, attrs)
          observability[:alarms] = create_alarms(name, attrs, tags)
          observability
        end

        private

        def create_xray_resources(name, attrs, tags, observability)
          observability[:sampling_rule] = aws_xray_sampling_rule(component_resource_name(name, :xray_sampling_rule), {
            rule_name: "#{name}-service-mesh-sampling", priority: 9000, version: 1, reservoir_size: 1,
            fixed_rate: attrs.observability.distributed_tracing_sampling_rate, url_path: "*", host: "*",
            http_method: "*", service_type: "*", service_name: "*", resource_arn: "*", tags: tags })
          observability[:xray_group] = aws_xray_group(component_resource_name(name, :xray_group), {
            group_name: attrs.mesh_name, filter_expression: "service(\"*#{attrs.mesh_name}*\")", tags: tags })
        end

        def create_log_groups(name, attrs, tags)
          attrs.services.each_with_object({}) do |service, groups|
            groups[service.name.to_sym] = aws_cloudwatch_log_group(component_resource_name(name, :log_group, service.name.to_sym), {
              name: "/aws/appmesh/#{attrs.mesh_name}/#{service.name}",
              retention_in_days: attrs.observability.log_retention_days, tags: tags.merge(Service: service.name) })
          end
        end

        def create_dashboard(name, attrs)
          widgets = [build_overview_widget(attrs), build_request_rate_widget(attrs), build_error_rate_widget(attrs)]
          widgets << build_circuit_breaker_widget(attrs) if attrs.traffic_management.circuit_breaker_enabled
          aws_cloudwatch_dashboard(component_resource_name(name, :dashboard), {
            dashboard_name: "#{name}-service-mesh",
            dashboard_body: JSON.generate({ widgets: widgets, periodOverride: "auto", start: "-PT6H" }) })
        end

        def build_overview_widget(attrs)
          { type: "metric", x: 0, y: 0, width: 24, height: 6,
            properties: { title: "Service Mesh Overview", period: 300, stat: "Average", region: attrs.regions.first,
              yAxis: { left: { label: "Response Time (ms)" } },
              metrics: attrs.services.map { |s| ["AWS/AppMesh", "TargetResponseTime", { MeshName: attrs.mesh_name, VirtualNodeName: s.name }] } } }
        end

        def build_request_rate_widget(attrs)
          { type: "metric", x: 0, y: 6, width: 12, height: 6,
            properties: { title: "Request Rate by Service", period: 300, stat: "Sum", region: attrs.regions.first,
              metrics: attrs.services.map { |s| ["AWS/AppMesh", "RequestCount", { MeshName: attrs.mesh_name, VirtualNodeName: s.name }] } } }
        end

        def build_error_rate_widget(attrs)
          { type: "metric", x: 12, y: 6, width: 12, height: 6,
            properties: { title: "Error Rate by Service", period: 300, stat: "Sum", region: attrs.regions.first,
              metrics: attrs.services.map { |s| ["AWS/AppMesh", "TargetConnectionErrorCount", { MeshName: attrs.mesh_name, VirtualNodeName: s.name }] } } }
        end

        def build_circuit_breaker_widget(attrs)
          { type: "metric", x: 0, y: 12, width: 24, height: 6,
            properties: { title: "Circuit Breaker Status", period: 60, stat: "Maximum", region: attrs.regions.first,
              yAxis: { left: { min: 0, max: 1 } },
              metrics: attrs.services.map { |s| ["AWS/AppMesh", "CircuitBreakerOpen", { MeshName: attrs.mesh_name, VirtualNodeName: s.name }] } } }
        end

        def create_alarms(name, attrs, tags)
          attrs.services.each_with_object({}) do |service, alarms|
            alarms["latency_#{service.name}".to_sym] = aws_cloudwatch_metric_alarm(
              component_resource_name(name, :alarm_latency, service.name.to_sym), {
                alarm_name: "#{name}-#{service.name}-high-latency", comparison_operator: "GreaterThanThreshold",
                evaluation_periods: "2", metric_name: "TargetResponseTime", namespace: "AWS/AppMesh", period: "300",
                statistic: "Average", threshold: (service.timeout_seconds * 1000 * 0.8).to_s,
                alarm_description: "Service #{service.name} latency is high",
                dimensions: { MeshName: attrs.mesh_name, VirtualNodeName: service.name }, tags: tags })
            alarms["errors_#{service.name}".to_sym] = aws_cloudwatch_metric_alarm(
              component_resource_name(name, :alarm_errors, service.name.to_sym), {
                alarm_name: "#{name}-#{service.name}-connection-errors", comparison_operator: "GreaterThanThreshold",
                evaluation_periods: "2", metric_name: "TargetConnectionErrorCount", namespace: "AWS/AppMesh",
                period: "300", statistic: "Sum", threshold: "10",
                alarm_description: "Service #{service.name} connection errors",
                dimensions: { MeshName: attrs.mesh_name, VirtualNodeName: service.name }, tags: tags })
          end
        end
      end
    end
  end
end
