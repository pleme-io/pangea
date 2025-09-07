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
require 'pangea/resources/aws_codedeploy_deployment_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CodeDeploy Deployment Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CodeDeploy deployment group attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_codedeploy_deployment_group(name, attributes = {})
        # Validate attributes using dry-struct
        group_attrs = Types::CodeDeployDeploymentGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_codedeploy_deployment_group, name) do
          # Basic configuration
          app_name group_attrs.app_name
          deployment_group_name group_attrs.deployment_group_name
          service_role_arn group_attrs.service_role_arn
          deployment_config_name group_attrs.deployment_config_name
          
          # Auto Scaling Groups
          if group_attrs.auto_scaling_groups.any?
            auto_scaling_groups group_attrs.auto_scaling_groups
          end
          
          # EC2 tag filters
          group_attrs.ec2_tag_filters.each do |filter|
            ec2_tag_filter do
              type filter[:type] if filter[:type]
              key filter[:key] if filter[:key]
              value filter[:value] if filter[:value]
            end
          end
          
          # On-premises instance tag filters
          group_attrs.on_premises_instance_tag_filters.each do |filter|
            on_premises_instance_tag_filter do
              type filter[:type] if filter[:type]
              key filter[:key] if filter[:key]
              value filter[:value] if filter[:value]
            end
          end
          
          # Trigger configurations
          group_attrs.trigger_configurations.each do |trigger|
            trigger_configuration do
              trigger_name trigger[:trigger_name]
              trigger_target_arn trigger[:trigger_target_arn]
              trigger_events trigger[:trigger_events]
            end
          end
          
          # Auto rollback configuration
          if group_attrs.auto_rollback_configuration.any?
            auto_rollback_configuration do
              enabled group_attrs.auto_rollback_configuration[:enabled] if group_attrs.auto_rollback_configuration.key?(:enabled)
              events group_attrs.auto_rollback_configuration[:events] if group_attrs.auto_rollback_configuration[:events]
            end
          end
          
          # Alarm configuration
          if group_attrs.alarm_configuration.any?
            alarm_configuration do
              alarms group_attrs.alarm_configuration[:alarms] if group_attrs.alarm_configuration[:alarms]
              enabled group_attrs.alarm_configuration[:enabled] if group_attrs.alarm_configuration.key?(:enabled)
              ignore_poll_alarm_failure group_attrs.alarm_configuration[:ignore_poll_alarm_failure] if group_attrs.alarm_configuration.key?(:ignore_poll_alarm_failure)
            end
          end
          
          # Deployment style
          if group_attrs.deployment_style.any?
            deployment_style do
              deployment_type group_attrs.deployment_style[:deployment_type] if group_attrs.deployment_style[:deployment_type]
              deployment_option group_attrs.deployment_style[:deployment_option] if group_attrs.deployment_style[:deployment_option]
            end
          end
          
          # Blue-green deployment configuration
          if group_attrs.blue_green_deployment_config.any?
            blue_green_deployment_config do
              if group_attrs.blue_green_deployment_config[:terminate_blue_instances_on_deployment_success]
                terminate_blue_instances_on_deployment_success do
                  action group_attrs.blue_green_deployment_config[:terminate_blue_instances_on_deployment_success][:action] if group_attrs.blue_green_deployment_config[:terminate_blue_instances_on_deployment_success][:action]
                  termination_wait_time_in_minutes group_attrs.blue_green_deployment_config[:terminate_blue_instances_on_deployment_success][:termination_wait_time_in_minutes] if group_attrs.blue_green_deployment_config[:terminate_blue_instances_on_deployment_success][:termination_wait_time_in_minutes]
                end
              end
              
              if group_attrs.blue_green_deployment_config[:deployment_ready_option]
                deployment_ready_option do
                  action_on_timeout group_attrs.blue_green_deployment_config[:deployment_ready_option][:action_on_timeout] if group_attrs.blue_green_deployment_config[:deployment_ready_option][:action_on_timeout]
                end
              end
              
              if group_attrs.blue_green_deployment_config[:green_fleet_provisioning_option]
                green_fleet_provisioning_option do
                  action group_attrs.blue_green_deployment_config[:green_fleet_provisioning_option][:action] if group_attrs.blue_green_deployment_config[:green_fleet_provisioning_option][:action]
                end
              end
            end
          end
          
          # Load balancer info
          if group_attrs.load_balancer_info.any?
            load_balancer_info do
              # ELB info
              if group_attrs.load_balancer_info[:elb_info]
                group_attrs.load_balancer_info[:elb_info].each do |elb|
                  elb_info do
                    name elb[:name] if elb[:name]
                  end
                end
              end
              
              # Target group info
              if group_attrs.load_balancer_info[:target_group_info]
                group_attrs.load_balancer_info[:target_group_info].each do |tg|
                  target_group_info do
                    name tg[:name] if tg[:name]
                  end
                end
              end
              
              # Target group pair info (for ECS)
              if group_attrs.load_balancer_info[:target_group_pair_info]
                group_attrs.load_balancer_info[:target_group_pair_info].each do |pair|
                  target_group_pair_info do
                    if pair[:prod_traffic_route]
                      prod_traffic_route do
                        listener_arns pair[:prod_traffic_route][:listener_arns] if pair[:prod_traffic_route][:listener_arns]
                      end
                    end
                    
                    if pair[:test_traffic_route]
                      test_traffic_route do
                        listener_arns pair[:test_traffic_route][:listener_arns] if pair[:test_traffic_route][:listener_arns]
                      end
                    end
                    
                    if pair[:target_groups]
                      pair[:target_groups].each do |tg|
                        target_group do
                          name tg[:name] if tg[:name]
                        end
                      end
                    end
                  end
                end
              end
            end
          end
          
          # ECS service
          if group_attrs.ecs_service.any?
            ecs_service do
              cluster_name group_attrs.ecs_service[:cluster_name] if group_attrs.ecs_service[:cluster_name]
              service_name group_attrs.ecs_service[:service_name] if group_attrs.ecs_service[:service_name]
            end
          end
          
          # Apply tags
          if group_attrs.tags.any?
            tags do
              group_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_codedeploy_deployment_group',
          name: name,
          resource_attributes: group_attrs.to_h,
          outputs: {
            id: "${aws_codedeploy_deployment_group.#{name}.id}",
            arn: "${aws_codedeploy_deployment_group.#{name}.arn}",
            deployment_group_id: "${aws_codedeploy_deployment_group.#{name}.deployment_group_id}",
            deployment_group_name: "${aws_codedeploy_deployment_group.#{name}.deployment_group_name}",
            app_name: "${aws_codedeploy_deployment_group.#{name}.app_name}"
          },
          computed: {
            uses_ec2_tags: group_attrs.uses_ec2_tags?,
            uses_on_premises_tags: group_attrs.uses_on_premises_tags?,
            uses_auto_scaling: group_attrs.uses_auto_scaling?,
            has_triggers: group_attrs.has_triggers?,
            auto_rollback_enabled: group_attrs.auto_rollback_enabled?,
            uses_alarms: group_attrs.uses_alarms?,
            blue_green_deployment: group_attrs.blue_green_deployment?,
            in_place_deployment: group_attrs.in_place_deployment?,
            uses_load_balancer: group_attrs.uses_load_balancer?,
            ecs_deployment: group_attrs.ecs_deployment?,
            traffic_control_enabled: group_attrs.traffic_control_enabled?,
            deployment_target_type: group_attrs.deployment_target_type
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)