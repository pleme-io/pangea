# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_autoscaling_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Auto Scaling Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Auto Scaling Group attributes
      # @option attributes [Integer] :min_size Minimum number of instances (required)
      # @option attributes [Integer] :max_size Maximum number of instances (required)
      # @option attributes [Integer] :desired_capacity Desired number of instances
      # @option attributes [Hash] :launch_template Launch template specification
      # @option attributes [Array<String>] :vpc_zone_identifier List of subnet IDs
      # @option attributes [String] :health_check_type Type of health check (EC2 or ELB)
      # @option attributes [Integer] :health_check_grace_period Grace period in seconds
      # @option attributes [Array<Hash>] :tags Tags to apply to instances
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Basic Auto Scaling Group with launch template
      #   asg = aws_autoscaling_group(:web_asg, {
      #     min_size: 2,
      #     max_size: 10,
      #     desired_capacity: 4,
      #     vpc_zone_identifier: [subnet_a.id, subnet_b.id],
      #     launch_template: {
      #       id: launch_template.id,
      #       version: "$Latest"
      #     },
      #     tags: [
      #       { key: "Name", value: "web-server", propagate_at_launch: true },
      #       { key: "Environment", value: "production", propagate_at_launch: true }
      #     ]
      #   })
      #
      # @example ASG with target groups and health checks
      #   asg = aws_autoscaling_group(:app_asg, {
      #     min_size: 1,
      #     max_size: 5,
      #     vpc_zone_identifier: private_subnet_ids,
      #     launch_template: { name: "app-template" },
      #     health_check_type: "ELB",
      #     health_check_grace_period: 300,
      #     target_group_arns: [target_group.arn]
      #   })
      def aws_autoscaling_group(name, attributes = {})
        # Validate attributes using dry-struct
        asg_attrs = Types::Types::AutoScalingGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_autoscaling_group, name) do
          # Required attributes
          min_size asg_attrs.min_size
          max_size asg_attrs.max_size
          
          # Optional sizing
          desired_capacity asg_attrs.desired_capacity if asg_attrs.desired_capacity
          default_cooldown asg_attrs.default_cooldown if asg_attrs.default_cooldown != 300
          
          # Launch configuration
          if asg_attrs.launch_configuration
            launch_configuration asg_attrs.launch_configuration
          elsif asg_attrs.launch_template
            launch_template do
              id asg_attrs.launch_template.id if asg_attrs.launch_template.id
              __send__(:name, asg_attrs.launch_template.name) if asg_attrs.launch_template.name
              version asg_attrs.launch_template.version
            end
          elsif asg_attrs.mixed_instances_policy
            mixed_instances_policy asg_attrs.mixed_instances_policy
          end
          
          # Network configuration
          vpc_zone_identifier asg_attrs.vpc_zone_identifier if asg_attrs.vpc_zone_identifier.any?
          availability_zones asg_attrs.availability_zones if asg_attrs.availability_zones.any?
          
          # Health check configuration
          health_check_type asg_attrs.health_check_type
          health_check_grace_period asg_attrs.health_check_grace_period
          
          # Termination policies
          termination_policies asg_attrs.termination_policies if asg_attrs.termination_policies.any?
          
          # Metrics
          if asg_attrs.enabled_metrics.any?
            enabled_metrics asg_attrs.enabled_metrics
            metrics_granularity asg_attrs.metrics_granularity
          end
          
          # Capacity and scaling options
          wait_for_capacity_timeout asg_attrs.wait_for_capacity_timeout
          min_elb_capacity asg_attrs.min_elb_capacity if asg_attrs.min_elb_capacity
          protect_from_scale_in asg_attrs.protect_from_scale_in if asg_attrs.protect_from_scale_in
          service_linked_role_arn asg_attrs.service_linked_role_arn if asg_attrs.service_linked_role_arn
          max_instance_lifetime asg_attrs.max_instance_lifetime if asg_attrs.max_instance_lifetime
          capacity_rebalance asg_attrs.capacity_rebalance if asg_attrs.capacity_rebalance
          
          # Load balancing
          target_group_arns asg_attrs.target_group_arns if asg_attrs.target_group_arns.any?
          load_balancers asg_attrs.load_balancers if asg_attrs.load_balancers.any?
          
          # Tags - handle as array of hashes
          if asg_attrs.tags.any?
            # Convert our AutoScalingTag objects to hash format expected by Terraform
            tag asg_attrs.tags.map(&:to_h)
          end
          
          # Instance refresh
          if asg_attrs.instance_refresh
            instance_refresh do
              preferences do
                min_healthy_percentage asg_attrs.instance_refresh.min_healthy_percentage
                instance_warmup asg_attrs.instance_refresh.instance_warmup if asg_attrs.instance_refresh.instance_warmup
                checkpoint_percentages asg_attrs.instance_refresh.checkpoint_percentages if asg_attrs.instance_refresh.checkpoint_percentages.any?
                checkpoint_delay asg_attrs.instance_refresh.checkpoint_delay if asg_attrs.instance_refresh.checkpoint_delay
              end
            end
          end
        end
        
        # Return resource reference with available outputs and computed properties
        ref = ResourceReference.new(
          type: 'aws_autoscaling_group',
          name: name,
          resource_attributes: asg_attrs.to_h,
          outputs: {
            id: "${aws_autoscaling_group.#{name}.id}",
            arn: "${aws_autoscaling_group.#{name}.arn}",
            name: "${aws_autoscaling_group.#{name}.name}",
            min_size: "${aws_autoscaling_group.#{name}.min_size}",
            max_size: "${aws_autoscaling_group.#{name}.max_size}",
            desired_capacity: "${aws_autoscaling_group.#{name}.desired_capacity}",
            default_cooldown: "${aws_autoscaling_group.#{name}.default_cooldown}",
            availability_zones: "${aws_autoscaling_group.#{name}.availability_zones}",
            load_balancers: "${aws_autoscaling_group.#{name}.load_balancers}",
            target_group_arns: "${aws_autoscaling_group.#{name}.target_group_arns}",
            health_check_type: "${aws_autoscaling_group.#{name}.health_check_type}",
            health_check_grace_period: "${aws_autoscaling_group.#{name}.health_check_grace_period}",
            vpc_zone_identifier: "${aws_autoscaling_group.#{name}.vpc_zone_identifier}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:uses_launch_template?) { asg_attrs.uses_launch_template? }
        ref.define_singleton_method(:uses_mixed_instances?) { asg_attrs.uses_mixed_instances? }
        ref.define_singleton_method(:uses_target_groups?) { asg_attrs.uses_target_groups? }
        ref.define_singleton_method(:uses_classic_load_balancers?) { asg_attrs.uses_classic_load_balancers? }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)