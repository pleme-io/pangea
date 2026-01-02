# frozen_string_literal: true

require 'json'

module Pangea
  module Components
    module ServiceMeshObservability
      # CloudWatch dashboard creation
      module Dashboard
        def create_dashboard(name, component_attrs)
          dashboard_name = component_attrs.dashboard_name || "#{name}-service-mesh"
          widgets = build_dashboard_widgets(component_attrs)

          aws_cloudwatch_dashboard(
            component_resource_name(name, :dashboard),
            {
              dashboard_name: dashboard_name,
              dashboard_body: JSON.generate({
                widgets: widgets,
                periodOverride: 'auto',
                start: '-PT6H'
              })
            }
          )
        end

        private

        def build_dashboard_widgets(component_attrs)
          widgets = []

          widgets << service_map_widget(component_attrs) if component_attrs.service_map.enabled
          widgets << request_rates_widget(component_attrs)
          widgets << latency_widget(component_attrs)
          widgets << error_rates_widget(component_attrs)
          widgets << resource_utilization_widget(component_attrs) if has_ecs_services?(component_attrs)
          widgets += custom_widgets(component_attrs)

          widgets
        end

        def service_map_widget(component_attrs)
          {
            type: 'metric',
            x: 0, y: 0, width: 24, height: 8,
            properties: {
              title: 'Service Map',
              view: 'servicemap',
              region: '${AWS::Region}',
              period: component_attrs.service_map.update_interval
            }
          }
        end

        def request_rates_widget(component_attrs)
          {
            type: 'metric',
            x: 0, y: 8, width: 12, height: 6,
            properties: {
              title: 'Request Rates',
              metrics: component_attrs.services.map do |service|
                ['AWS/X-Ray', 'TracedRequestCount', { ServiceName: service.name }]
              end,
              period: 300, stat: 'Sum', region: '${AWS::Region}',
              yAxis: { left: { label: 'Requests' } }
            }
          }
        end

        def latency_widget(component_attrs)
          {
            type: 'metric',
            x: 12, y: 8, width: 12, height: 6,
            properties: {
              title: 'Service Latencies',
              metrics: component_attrs.services.map do |service|
                ['AWS/X-Ray', 'TracedRequestLatency', { ServiceName: service.name }]
              end,
              period: 300, stat: 'Average', region: '${AWS::Region}',
              yAxis: { left: { label: 'Milliseconds' } }
            }
          }
        end

        def error_rates_widget(component_attrs)
          {
            type: 'metric',
            x: 0, y: 14, width: 12, height: 6,
            properties: {
              title: 'Error Rates',
              metrics: [],
              period: 300, stat: 'Average', region: '${AWS::Region}',
              yAxis: { left: { label: 'Error %' } },
              annotations: {
                horizontal: [{
                  label: 'Error Threshold',
                  value: component_attrs.alerting.error_rate_threshold * 100
                }]
              }
            }
          }
        end

        def resource_utilization_widget(component_attrs)
          {
            type: 'metric',
            x: 12, y: 14, width: 12, height: 6,
            properties: {
              title: 'Resource Utilization',
              metrics: component_attrs.services.select { |s| s.task_definition_ref }.flat_map do |service|
                [
                  ['AWS/ECS', 'CPUUtilization', { ServiceName: service.name, ClusterName: service.cluster_ref.name }],
                  ['.', 'MemoryUtilization', { ServiceName: service.name, ClusterName: service.cluster_ref.name }]
                ]
              end,
              period: 300, stat: 'Average', region: '${AWS::Region}',
              yAxis: { left: { label: 'Percentage' } }
            }
          }
        end

        def custom_widgets(component_attrs)
          component_attrs.dashboard_widgets.each_with_index.map do |widget, index|
            {
              type: widget.type,
              x: (index % 2) * 12,
              y: 20 + (index / 2) * 6,
              width: widget.width,
              height: widget.height,
              properties: widget.properties.merge({
                title: widget.title,
                metrics: widget.metrics
              })
            }
          end
        end

        def has_ecs_services?(component_attrs)
          component_attrs.services.any? { |s| s.task_definition_ref }
        end
      end
    end
  end
end
