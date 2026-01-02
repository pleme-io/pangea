# frozen_string_literal: true

module Pangea
  module Components
    module ServiceMeshObservability
      # Anomaly detection and Container Insights
      module Anomaly
        def create_anomaly_detectors(name, component_attrs)
          return {} unless component_attrs.anomaly_detection_enabled

          anomaly_detectors = {}

          component_attrs.services.each do |service|
            anomaly_detectors[service.name.to_sym] = aws_cloudwatch_anomaly_detector(
              component_resource_name(name, :anomaly_detector, service.name.to_sym),
              {
                metric_name: 'TracedRequestLatency',
                namespace: 'AWS/X-Ray',
                dimensions: { ServiceName: service.name },
                stat: 'Average'
              }
            )
          end

          anomaly_detectors
        end

        def configure_container_insights(name, component_attrs)
          return unless component_attrs.container_insights_enabled

          component_attrs.services.each do |service|
            next unless service.cluster_ref

            aws_ecs_cluster_capacity_providers(
              component_resource_name(name, :container_insights, service.name.to_sym),
              {
                cluster_name: service.cluster_ref.name,
                capacity_providers: %w[FARGATE FARGATE_SPOT],
                default_capacity_provider_strategy: [{
                  capacity_provider: 'FARGATE',
                  weight: 1,
                  base: 0
                }]
              }
            )
          end
        end
      end
    end
  end
end
