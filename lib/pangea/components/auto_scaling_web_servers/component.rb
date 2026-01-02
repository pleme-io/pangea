# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/components/base'
require 'pangea/components/auto_scaling_web_servers/types'
require 'pangea/resources/aws'
require_relative 'component/launch_template'
require_relative 'component/scaling_policies'
require_relative 'component/lifecycle'

module Pangea
  module Components
    # Auto Scaling Group for web servers with CPU-based scaling and health checks
    def auto_scaling_web_servers(name, attributes = {})
      include Base
      include Resources::AWS
      include AutoScalingWebServersComponent::LaunchTemplate
      include AutoScalingWebServersComponent::ScalingPolicies
      include AutoScalingWebServersComponent::Lifecycle

      component_attrs = AutoScalingWebServers::AutoScalingWebServersAttributes.new(attributes)
      component_tag_set = component_tags('AutoScalingWebServers', name, component_attrs.tags)

      resources = {}

      # Create Launch Template
      launch_template_ref = create_launch_template(name, component_attrs, component_tag_set)
      resources[:launch_template] = launch_template_ref

      # Prepare ASG tags
      asg_tags_list = component_attrs.asg_tags.merge(component_tag_set).map do |key, value|
        { key: key.to_s, value: value.to_s, propagate_at_launch: component_attrs.propagate_at_launch }
      end

      # Create Auto Scaling Group
      asg_attrs = build_asg_attributes(name, component_attrs, launch_template_ref, asg_tags_list, component_tag_set)
      asg_ref = aws_autoscaling_group(component_resource_name(name, :asg), asg_attrs)
      resources[:asg] = asg_ref

      # Create target group attachments
      attachments = create_target_group_attachments(name, component_attrs, asg_ref)
      resources[:attachments] = attachments unless attachments.empty?

      # Create scaling policies
      policies = create_scaling_policies(name, component_attrs, asg_ref)
      resources[:policies] = policies unless policies.empty?

      # Create CloudWatch alarms
      resources[:alarms] = create_cloudwatch_alarms(name, component_attrs, asg_ref, component_tag_set)

      # Create lifecycle hooks
      hooks = create_lifecycle_hooks(name, component_attrs, asg_ref)
      resources[:hooks] = hooks unless hooks.empty?

      # Build outputs
      outputs = build_component_outputs(name, component_attrs, launch_template_ref, asg_ref)

      create_component_reference('auto_scaling_web_servers', name, component_attrs.to_h, resources, outputs)
    end

    private

    def build_asg_attributes(name, component_attrs, launch_template_ref, asg_tags_list, component_tag_set)
      asg_attrs = {
        name: "#{name}-asg",
        launch_template: { id: launch_template_ref.id, version: "$Latest" },
        min_size: component_attrs.min_size,
        max_size: component_attrs.max_size,
        desired_capacity: component_attrs.desired_capacity,
        default_cooldown: component_attrs.default_cooldown,
        health_check_type: component_attrs.health_check_type,
        health_check_grace_period: component_attrs.health_check_grace_period,
        vpc_zone_identifier: component_attrs.subnet_refs.map(&:id),
        availability_zones: component_attrs.availability_zones,
        target_group_arns: component_attrs.target_group_refs.map(&:arn),
        load_balancers: component_attrs.load_balancer_names,
        termination_policies: component_attrs.termination_policies,
        protect_from_scale_in: component_attrs.protect_from_scale_in,
        service_linked_role_arn: component_attrs.service_linked_role_arn,
        enabled_metrics: component_attrs.monitoring.enabled_metrics,
        tag: asg_tags_list,
        tags: component_tag_set
      }.compact

      if component_attrs.enable_mixed_instances && component_attrs.mixed_instances_policy
        asg_attrs[:mixed_instances_policy] = component_attrs.mixed_instances_policy
        asg_attrs.delete(:launch_template)
      end

      if component_attrs.enable_warm_pool && component_attrs.warm_pool_config
        asg_attrs[:warm_pool] = component_attrs.warm_pool_config
      end

      asg_attrs
    end
  end
end
