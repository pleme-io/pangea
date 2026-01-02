# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module AutoScalingWebServersComponent
      module Lifecycle
        def create_target_group_attachments(name, component_attrs, asg_ref)
          attachments = {}

          component_attrs.target_group_refs.each_with_index do |tg_ref, index|
            attachment_ref = aws_autoscaling_attachment(
              component_resource_name(name, :attachment, "tg#{index}".to_sym),
              {
                autoscaling_group_name: asg_ref.name,
                alb_target_group_arn: tg_ref.arn
              }
            )
            attachments["tg#{index}".to_sym] = attachment_ref
          end

          attachments
        end

        def create_lifecycle_hooks(name, component_attrs, asg_ref)
          hooks = {}

          component_attrs.lifecycle_hooks.each_with_index do |hook_config, index|
            hook_ref = aws_autoscaling_lifecycle_hook(
              component_resource_name(name, :hook, "hook#{index}".to_sym),
              hook_config.merge({ autoscaling_group_name: asg_ref.name })
            )
            hooks["hook#{index}".to_sym] = hook_ref
          end

          hooks
        end

        def estimate_instance_cost(instance_type)
          case instance_type
          when /^t3\.nano$/ then 4.0
          when /^t3\.micro$/ then 8.0
          when /^t3\.small$/ then 16.0
          when /^t3\.medium$/ then 32.0
          when /^t3\.large$/ then 64.0
          when /^c5\.large$/ then 70.0
          when /^c5\.xlarge$/ then 140.0
          when /^r5\.large$/ then 100.0
          else 50.0
          end
        end

        def build_component_outputs(name, component_attrs, launch_template_ref, asg_ref)
          {
            asg_name: asg_ref.name,
            asg_arn: asg_ref.arn,
            launch_template_id: launch_template_ref.id,
            launch_template_version: launch_template_ref.latest_version,
            min_size: component_attrs.min_size,
            max_size: component_attrs.max_size,
            desired_capacity: component_attrs.desired_capacity || component_attrs.min_size,
            target_group_arns: component_attrs.target_group_refs.map(&:arn),
            security_features: build_security_features(component_attrs),
            availability_zones: extract_availability_zones(component_attrs),
            estimated_monthly_cost: (component_attrs.desired_capacity || component_attrs.min_size) * estimate_instance_cost(component_attrs.instance_type)
          }
        end

        def build_security_features(component_attrs)
          [
            "Encrypted EBS Volumes",
            "IMDSv2 Required",
            "Auto Scaling Policies",
            "CloudWatch Monitoring",
            ("Health Check Integration" if component_attrs.health_check_type == "ELB"),
            ("Mixed Instance Types" if component_attrs.enable_mixed_instances),
            ("Warm Pool" if component_attrs.enable_warm_pool)
          ].compact
        end

        def extract_availability_zones(component_attrs)
          component_attrs.subnet_refs.map do |subnet|
            subnet.respond_to?(:availability_zone) ? subnet.availability_zone : nil
          end.compact.uniq
        end
      end
    end
  end
end
