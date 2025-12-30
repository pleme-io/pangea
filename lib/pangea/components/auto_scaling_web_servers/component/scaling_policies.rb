# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module AutoScalingWebServersComponent
      module ScalingPolicies
        def create_scaling_policies(name, component_attrs, asg_ref)
          policies = {}

          if component_attrs.enable_cpu_scaling
            policies[:cpu_scaling] = create_cpu_scaling_policy(name, component_attrs, asg_ref)
          end

          component_attrs.scaling_policies.each_with_index do |policy_config, index|
            policy_name = "custom_#{index}"
            policies[policy_name.to_sym] = create_custom_scaling_policy(name, policy_config, policy_name, asg_ref)
          end

          policies
        end

        def create_cpu_scaling_policy(name, component_attrs, asg_ref)
          aws_autoscaling_policy(component_resource_name(name, :policy, :cpu), {
            name: "#{name}-cpu-scaling-policy",
            autoscaling_group_name: asg_ref.name,
            policy_type: "TargetTrackingScaling",
            target_tracking_configuration: {
              target_value: component_attrs.cpu_target_value,
              predefined_metric_specification: { predefined_metric_type: "ASGAverageCPUUtilization" },
              scale_out_cooldown: 300,
              scale_in_cooldown: 300,
              disable_scale_in: false
            }
          })
        end

        def create_custom_scaling_policy(name, policy_config, policy_name, asg_ref)
          case policy_config.policy_type
          when "TargetTrackingScaling"
            create_target_tracking_policy(name, policy_config, policy_name, asg_ref)
          when "StepScaling", "SimpleScaling"
            create_step_or_simple_policy(name, policy_config, policy_name, asg_ref)
          end
        end

        def create_target_tracking_policy(name, policy_config, policy_name, asg_ref)
          predefined_metric = build_predefined_metric(policy_config)

          aws_autoscaling_policy(component_resource_name(name, :policy, policy_name.to_sym), {
            name: "#{name}-#{policy_name}-policy",
            autoscaling_group_name: asg_ref.name,
            policy_type: "TargetTrackingScaling",
            target_tracking_configuration: {
              target_value: policy_config.target_value,
              predefined_metric_specification: predefined_metric,
              scale_out_cooldown: policy_config.scale_out_cooldown,
              scale_in_cooldown: policy_config.scale_in_cooldown,
              disable_scale_in: policy_config.disable_scale_in
            }.compact
          })
        end

        def build_predefined_metric(policy_config)
          case policy_config.metric_type
          when "ASGAverageCPUUtilization" then { predefined_metric_type: "ASGAverageCPUUtilization" }
          when "ASGAverageNetworkIn" then { predefined_metric_type: "ASGAverageNetworkIn" }
          when "ASGAverageNetworkOut" then { predefined_metric_type: "ASGAverageNetworkOut" }
          when "ALBRequestCountPerTarget"
            { predefined_metric_type: "ALBRequestCountPerTarget", resource_label: policy_config.target_group_arn }
          end
        end

        def create_step_or_simple_policy(name, policy_config, policy_name, asg_ref)
          policy_attrs = {
            name: "#{name}-#{policy_name}-policy",
            autoscaling_group_name: asg_ref.name,
            policy_type: policy_config.policy_type,
            adjustment_type: policy_config.adjustment_type,
            cooldown: policy_config.scale_out_cooldown
          }

          if policy_config.policy_type == "StepScaling"
            policy_attrs[:step_adjustments] = policy_config.step_adjustments
            policy_attrs[:min_adjustment_magnitude] = policy_config.min_adjustment_magnitude
          else
            policy_attrs[:scaling_adjustment] = policy_config.scaling_adjustment
          end

          aws_autoscaling_policy(component_resource_name(name, :policy, policy_name.to_sym), policy_attrs.compact)
        end

        def create_cloudwatch_alarms(name, component_attrs, asg_ref, component_tag_set)
          {
            cpu_high: create_cpu_alarm(name, asg_ref, component_tag_set),
            instance_count: create_instance_count_alarm(name, component_attrs, asg_ref, component_tag_set),
            network_high: create_network_alarm(name, asg_ref, component_tag_set)
          }
        end

        def create_cpu_alarm(name, asg_ref, component_tag_set)
          aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :cpu_high), {
            alarm_name: "#{name}-asg-cpu-utilization-high",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: "2",
            metric_name: "CPUUtilization",
            namespace: "AWS/EC2",
            period: "300",
            statistic: "Average",
            threshold: "80.0",
            alarm_description: "ASG CPU utilization is consistently high",
            dimensions: { AutoScalingGroupName: asg_ref.name },
            tags: component_tag_set
          })
        end

        def create_instance_count_alarm(name, component_attrs, asg_ref, component_tag_set)
          aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :instance_count), {
            alarm_name: "#{name}-asg-instance-count-low",
            comparison_operator: "LessThanThreshold",
            evaluation_periods: "2",
            metric_name: "GroupInServiceInstances",
            namespace: "AWS/AutoScaling",
            period: "300",
            statistic: "Average",
            threshold: component_attrs.min_size.to_s,
            alarm_description: "ASG has fewer instances than minimum required",
            dimensions: { AutoScalingGroupName: asg_ref.name },
            tags: component_tag_set
          })
        end

        def create_network_alarm(name, asg_ref, component_tag_set)
          aws_cloudwatch_metric_alarm(component_resource_name(name, :alarm, :network_high), {
            alarm_name: "#{name}-asg-network-utilization-high",
            comparison_operator: "GreaterThanThreshold",
            evaluation_periods: "3",
            metric_name: "NetworkOut",
            namespace: "AWS/EC2",
            period: "300",
            statistic: "Average",
            threshold: "100000000",
            alarm_description: "ASG network utilization is high",
            dimensions: { AutoScalingGroupName: asg_ref.name },
            tags: component_tag_set
          })
        end
      end
    end
  end
end
