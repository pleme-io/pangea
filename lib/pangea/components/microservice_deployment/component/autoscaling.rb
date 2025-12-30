# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module MicroserviceDeploymentComponent
      module Autoscaling
        def configure_autoscaling(name, component_attrs, service_ref)
          return {} unless component_attrs.auto_scaling.enabled

          scalable_target_ref = create_scalable_target(name, component_attrs, service_ref)
          cpu_policy_ref = create_cpu_scaling_policy(name, component_attrs, scalable_target_ref)
          memory_policy_ref = create_memory_scaling_policy(name, component_attrs, scalable_target_ref)

          {
            scalable_target: scalable_target_ref,
            cpu_scaling_policy: cpu_policy_ref,
            memory_scaling_policy: memory_policy_ref
          }
        end

        private

        def create_scalable_target(name, component_attrs, service_ref)
          aws_appautoscaling_target(component_resource_name(name, :scalable_target), {
            service_namespace: 'ecs',
            resource_id: "service/#{component_attrs.cluster_ref.name}/#{service_ref.name}",
            scalable_dimension: 'ecs:service:DesiredCount',
            min_capacity: component_attrs.auto_scaling.min_tasks,
            max_capacity: component_attrs.auto_scaling.max_tasks
          })
        end

        def create_cpu_scaling_policy(name, component_attrs, scalable_target_ref)
          aws_appautoscaling_policy(component_resource_name(name, :cpu_scaling_policy), {
            name: "#{name}-cpu-scaling", service_namespace: 'ecs',
            resource_id: scalable_target_ref.resource_id,
            scalable_dimension: scalable_target_ref.scalable_dimension,
            policy_type: 'TargetTrackingScaling',
            target_tracking_scaling_policy_configuration: {
              target_value: component_attrs.auto_scaling.target_cpu,
              predefined_metric_specification: { predefined_metric_type: 'ECSServiceAverageCPUUtilization' },
              scale_out_cooldown: component_attrs.auto_scaling.scale_out_cooldown,
              scale_in_cooldown: component_attrs.auto_scaling.scale_in_cooldown
            }
          })
        end

        def create_memory_scaling_policy(name, component_attrs, scalable_target_ref)
          aws_appautoscaling_policy(component_resource_name(name, :memory_scaling_policy), {
            name: "#{name}-memory-scaling", service_namespace: 'ecs',
            resource_id: scalable_target_ref.resource_id,
            scalable_dimension: scalable_target_ref.scalable_dimension,
            policy_type: 'TargetTrackingScaling',
            target_tracking_scaling_policy_configuration: {
              target_value: component_attrs.auto_scaling.target_memory,
              predefined_metric_specification: { predefined_metric_type: 'ECSServiceAverageMemoryUtilization' },
              scale_out_cooldown: component_attrs.auto_scaling.scale_out_cooldown,
              scale_in_cooldown: component_attrs.auto_scaling.scale_in_cooldown
            }
          })
        end
      end
    end
  end
end
