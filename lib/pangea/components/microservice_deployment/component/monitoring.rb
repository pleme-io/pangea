# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module MicroserviceDeploymentComponent
      module Monitoring
        def create_cloudwatch_alarms(name, component_attrs, service_ref, component_tag_set)
          {
            cpu_high: create_cpu_alarm(name, component_attrs, service_ref, component_tag_set),
            memory_high: create_memory_alarm(name, component_attrs, service_ref, component_tag_set),
            task_count_low: create_task_count_alarm(name, component_attrs, service_ref, component_tag_set)
          }
        end

        def create_xray_sampling_rule(name, component_attrs, component_tag_set)
          return nil unless component_attrs.tracing.enabled && component_attrs.tracing.x_ray
          aws_xray_sampling_rule(component_resource_name(name, :xray_sampling_rule), {
            rule_name: "#{name}-sampling", priority: 9000, version: 1, reservoir_size: 1,
            fixed_rate: component_attrs.tracing.sampling_rate, url_path: '*', host: '*',
            http_method: '*', service_type: '*', service_name: component_attrs.task_definition_family,
            resource_arn: '*', attributes: {}, tags: component_tag_set
          })
        end

        private

        def create_cpu_alarm(name, component_attrs, service_ref, component_tag_set)
          aws_cloudwatch_metric_alarm(component_resource_name(name, :cpu_alarm), {
            alarm_name: "#{name}-service-cpu-high", comparison_operator: 'GreaterThanThreshold',
            evaluation_periods: '2', metric_name: 'CPUUtilization', namespace: 'AWS/ECS',
            period: '300', statistic: 'Average', threshold: '85.0',
            alarm_description: 'Service CPU utilization is high',
            dimensions: { ServiceName: service_ref.name, ClusterName: component_attrs.cluster_ref.name },
            tags: component_tag_set
          })
        end

        def create_memory_alarm(name, component_attrs, service_ref, component_tag_set)
          aws_cloudwatch_metric_alarm(component_resource_name(name, :memory_alarm), {
            alarm_name: "#{name}-service-memory-high", comparison_operator: 'GreaterThanThreshold',
            evaluation_periods: '2', metric_name: 'MemoryUtilization', namespace: 'AWS/ECS',
            period: '300', statistic: 'Average', threshold: '85.0',
            alarm_description: 'Service memory utilization is high',
            dimensions: { ServiceName: service_ref.name, ClusterName: component_attrs.cluster_ref.name },
            tags: component_tag_set
          })
        end

        def create_task_count_alarm(name, component_attrs, service_ref, component_tag_set)
          threshold = component_attrs.auto_scaling.enabled ?
            component_attrs.auto_scaling.min_tasks.to_s : component_attrs.desired_count.to_s
          aws_cloudwatch_metric_alarm(component_resource_name(name, :task_count_alarm), {
            alarm_name: "#{name}-service-tasks-low", comparison_operator: 'LessThanThreshold',
            evaluation_periods: '2', metric_name: 'RunningTaskCount', namespace: 'AWS/ECS',
            period: '60', statistic: 'Average', threshold: threshold,
            alarm_description: 'Service has fewer running tasks than expected',
            dimensions: { ServiceName: service_ref.name, ClusterName: component_attrs.cluster_ref.name },
            tags: component_tag_set
          })
        end
      end
    end
  end
end
