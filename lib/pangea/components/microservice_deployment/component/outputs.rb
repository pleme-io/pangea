# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module MicroserviceDeploymentComponent
      module Outputs
        def calculate_outputs(service_ref, task_def_ref, log_group_ref, component_attrs, load_balancers)
          {
            service_name: service_ref.name, service_arn: service_ref.id, task_definition_arn: task_def_ref.arn,
            task_definition_family: component_attrs.task_definition_family,
            cluster_name: component_attrs.cluster_ref.name, desired_count: component_attrs.desired_count,
            launch_type: component_attrs.launch_type, log_group_name: log_group_ref.name,
            service_discovery_endpoint: service_discovery_endpoint(component_attrs),
            resilience_features: resilience_features(component_attrs, load_balancers),
            monitoring_features: monitoring_features(component_attrs),
            estimated_monthly_cost: estimate_microservice_cost(component_attrs)
          }
        end

        private

        def service_discovery_endpoint(component_attrs)
          return nil unless component_attrs.service_discovery
          "#{component_attrs.service_discovery.service_name}.#{component_attrs.service_discovery.namespace_id}"
        end

        def resilience_features(component_attrs, load_balancers)
          [
            ('Circuit Breaker' if component_attrs.circuit_breaker.enabled),
            ('Auto Scaling' if component_attrs.auto_scaling.enabled),
            ('Health Checks' if load_balancers.any?),
            ('Service Discovery' if component_attrs.service_discovery),
            ('Distributed Tracing' if component_attrs.tracing.enabled),
            ('Blue-Green Deployment' if component_attrs.enable_blue_green)
          ].compact
        end

        def monitoring_features(component_attrs)
          [
            'CloudWatch Logs', 'CloudWatch Alarms',
            ('X-Ray Tracing' if component_attrs.tracing.x_ray),
            ('Jaeger Tracing' if component_attrs.tracing.jaeger),
            ('Zipkin Tracing' if component_attrs.tracing.zipkin)
          ].compact
        end

        def estimate_microservice_cost(attrs)
          vcpu_hour_cost = 0.04048
          gb_hour_cost = 0.004445
          vcpus = attrs.task_cpu.to_f / 1024
          memory_gb = attrs.task_memory.to_f / 1024
          hourly_cost_per_task = (vcpus * vcpu_hour_cost) + (memory_gb * gb_hour_cost)
          task_count = attrs.auto_scaling.enabled ? attrs.auto_scaling.min_tasks : attrs.desired_count
          cost = hourly_cost_per_task * task_count * 730
          cost += 5.0 # CloudWatch Logs
          cost += 22.0 if attrs.target_group_refs.any? # Load Balancer
          cost += 1.0 if attrs.service_discovery # Service Discovery
          cost += 5.0 if attrs.tracing.enabled && attrs.tracing.x_ray # X-Ray
          cost.round(2)
        end
      end
    end
  end
end
