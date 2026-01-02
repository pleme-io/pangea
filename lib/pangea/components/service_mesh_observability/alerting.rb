# frozen_string_literal: true

module Pangea
  module Components
    module ServiceMeshObservability
      # CloudWatch alarms for service mesh
      module Alerting
        def create_alert_topic(name, component_attrs, component_tag_set)
          return nil if !component_attrs.alerting.enabled || component_attrs.alerting.notification_channel_ref

          aws_sns_topic(
            component_resource_name(name, :alert_topic),
            {
              name: "#{name}-alerts",
              display_name: "#{component_attrs.mesh_name} Alerts",
              tags: component_tag_set
            }
          )
        end

        def create_service_alarms(name, component_attrs, notification_arn, component_tag_set)
          return {} unless component_attrs.alerting.enabled

          alarms = {}

          component_attrs.services.each do |service|
            service_alarms = {}
            service_alarms[:latency] = create_latency_alarm(name, service, component_attrs, notification_arn, component_tag_set)
            service_alarms[:error_rate] = create_error_rate_alarm(name, service, component_attrs, notification_arn, component_tag_set)
            service_alarms[:availability] = create_availability_alarm(name, service, component_attrs, notification_arn, component_tag_set)

            if service.task_definition_ref
              service_alarms[:cpu] = create_cpu_alarm(name, service, notification_arn, component_tag_set)
              service_alarms[:memory] = create_memory_alarm(name, service, notification_arn, component_tag_set)
            end

            alarms[service.name.to_sym] = service_alarms
          end

          alarms
        end

        private

        def create_latency_alarm(name, service, component_attrs, notification_arn, tags)
          aws_cloudwatch_metric_alarm(
            component_resource_name(name, :alarm_latency, service.name.to_sym),
            {
              alarm_name: "#{name}-#{service.name}-high-latency",
              comparison_operator: 'GreaterThanThreshold',
              evaluation_periods: '2',
              metric_name: 'TracedRequestLatency',
              namespace: 'AWS/X-Ray',
              period: '300',
              statistic: 'Average',
              threshold: component_attrs.alerting.latency_threshold_ms.to_s,
              alarm_description: "Service #{service.name} latency is high",
              dimensions: { ServiceName: service.name },
              alarm_actions: notification_arn ? [notification_arn] : nil,
              tags: tags
            }.compact
          )
        end

        def create_error_rate_alarm(name, service, component_attrs, notification_arn, tags)
          aws_cloudwatch_metric_alarm(
            component_resource_name(name, :alarm_errors, service.name.to_sym),
            {
              alarm_name: "#{name}-#{service.name}-error-rate",
              comparison_operator: 'GreaterThanThreshold',
              evaluation_periods: '2',
              threshold: (component_attrs.alerting.error_rate_threshold * 100).to_s,
              alarm_description: "Service #{service.name} error rate is high",
              alarm_actions: notification_arn ? [notification_arn] : nil,
              tags: tags,
              metric_query: error_rate_metric_query(service)
            }
          )
        end

        def create_availability_alarm(name, service, component_attrs, notification_arn, tags)
          aws_cloudwatch_metric_alarm(
            component_resource_name(name, :alarm_availability, service.name.to_sym),
            {
              alarm_name: "#{name}-#{service.name}-availability",
              comparison_operator: 'LessThanThreshold',
              evaluation_periods: '3',
              threshold: (component_attrs.alerting.availability_threshold * 100).to_s,
              alarm_description: "Service #{service.name} availability is low",
              alarm_actions: notification_arn ? [notification_arn] : nil,
              tags: tags,
              metric_query: availability_metric_query(service)
            }
          )
        end

        def create_cpu_alarm(name, service, notification_arn, tags)
          aws_cloudwatch_metric_alarm(
            component_resource_name(name, :alarm_cpu, service.name.to_sym),
            {
              alarm_name: "#{name}-#{service.name}-cpu-high",
              comparison_operator: 'GreaterThanThreshold',
              evaluation_periods: '2',
              metric_name: 'CPUUtilization',
              namespace: 'AWS/ECS',
              period: '300',
              statistic: 'Average',
              threshold: '80',
              alarm_description: "Service #{service.name} CPU utilization is high",
              dimensions: { ServiceName: service.name, ClusterName: service.cluster_ref.name },
              alarm_actions: notification_arn ? [notification_arn] : nil,
              tags: tags
            }.compact
          )
        end

        def create_memory_alarm(name, service, notification_arn, tags)
          aws_cloudwatch_metric_alarm(
            component_resource_name(name, :alarm_memory, service.name.to_sym),
            {
              alarm_name: "#{name}-#{service.name}-memory-high",
              comparison_operator: 'GreaterThanThreshold',
              evaluation_periods: '2',
              metric_name: 'MemoryUtilization',
              namespace: 'AWS/ECS',
              period: '300',
              statistic: 'Average',
              threshold: '80',
              alarm_description: "Service #{service.name} memory utilization is high",
              dimensions: { ServiceName: service.name, ClusterName: service.cluster_ref.name },
              alarm_actions: notification_arn ? [notification_arn] : nil,
              tags: tags
            }.compact
          )
        end

        def error_rate_metric_query(service)
          [
            { id: 'error_rate', expression: '(errors / requests) * 100', label: 'Error Rate', return_data: true },
            { id: 'errors', metric: xray_metric(service, 'ErrorCount') },
            { id: 'requests', metric: xray_metric(service, 'TracedRequestCount') }
          ]
        end

        def availability_metric_query(service)
          [
            { id: 'availability', expression: '(1 - (errors / requests)) * 100', label: 'Availability', return_data: true },
            { id: 'errors', metric: xray_metric(service, 'ErrorCount') },
            { id: 'requests', metric: xray_metric(service, 'TracedRequestCount') }
          ]
        end

        def xray_metric(service, metric_name)
          {
            metric_name: metric_name,
            namespace: 'AWS/X-Ray',
            period: 300,
            stat: 'Sum',
            dimensions: { ServiceName: service.name }
          }
        end
      end
    end
  end
end
