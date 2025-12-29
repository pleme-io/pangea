# frozen_string_literal: true

module Pangea
  module Components
    module ServiceMeshObservability
      # Helper methods for cost estimation and outputs
      module Helpers
        def estimate_observability_cost(attrs)
          cost = 0.0
          cost += xray_cost(attrs)
          cost += cloudwatch_logs_cost(attrs)
          cost += cloudwatch_metrics_cost(attrs)
          cost += cloudwatch_alarms_cost(attrs)
          cost += 3.00 # Dashboard cost
          cost += container_insights_cost(attrs)
          cost.round(2)
        end

        def build_observability_outputs(component_attrs, resources, alarms)
          dashboard_name = component_attrs.dashboard_name || "#{component_attrs.mesh_name}-service-mesh"

          {
            mesh_name: component_attrs.mesh_name,
            dashboard_url: "https://console.aws.amazon.com/cloudwatch/home?region=${AWS::Region}#dashboards:name=#{dashboard_name}",
            xray_service_map_url: 'https://console.aws.amazon.com/xray/home?region=${AWS::Region}#/service-map',
            services_monitored: component_attrs.services.map(&:name),
            observability_features: enabled_features(component_attrs, resources),
            monitoring_metrics: monitoring_metrics(component_attrs),
            alarms_configured: alarms.values.flat_map { |service_alarms| service_alarms.keys }.uniq.map(&:to_s),
            sampling_rate: component_attrs.tracing.sampling_rate,
            log_retention_days: component_attrs.log_aggregation.retention_days,
            estimated_monthly_cost: estimate_observability_cost(component_attrs)
          }
        end

        private

        def xray_cost(attrs)
          return 0.0 unless attrs.xray_enabled

          traces_per_month = attrs.services.length * 1_000_000 * attrs.tracing.sampling_rate
          (traces_per_month / 1_000_000) * 5.00 + (traces_per_month / 1_000_000) * 0.50
        end

        def cloudwatch_logs_cost(attrs)
          return 0.0 unless attrs.log_aggregation.enabled

          log_gb_per_month = attrs.services.length * 50
          log_gb_per_month * 0.50 + log_gb_per_month * 0.03
        end

        def cloudwatch_metrics_cost(attrs)
          metrics_count = attrs.services.length * 10
          metrics_count > 10_000 ? (metrics_count - 10_000) * 0.30 : 0.0
        end

        def cloudwatch_alarms_cost(attrs)
          return 0.0 unless attrs.alerting.enabled

          attrs.services.length * 4 * 0.10
        end

        def container_insights_cost(attrs)
          attrs.container_insights_enabled ? attrs.services.length * 5.00 : 0.0
        end

        def enabled_features(component_attrs, resources)
          [
            ('X-Ray Distributed Tracing' if component_attrs.xray_enabled),
            ('Service Map Visualization' if component_attrs.service_map.enabled),
            ('CloudWatch Dashboard' if resources[:dashboard]),
            ('Container Insights' if component_attrs.container_insights_enabled),
            ('Log Aggregation' if component_attrs.log_aggregation.enabled),
            ('Anomaly Detection' if component_attrs.anomaly_detection_enabled),
            ('Cost Tracking' if component_attrs.cost_tracking_enabled)
          ].compact
        end

        def monitoring_metrics(component_attrs)
          [
            'Request Rate',
            'Latency (p50, p90, p99)',
            'Error Rate',
            'Availability',
            ('CPU Utilization' if component_attrs.services.any? { |s| s.task_definition_ref }),
            ('Memory Utilization' if component_attrs.services.any? { |s| s.task_definition_ref })
          ].compact
        end
      end
    end
  end
end
