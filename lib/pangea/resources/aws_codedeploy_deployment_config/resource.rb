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
require 'pangea/resources/aws_codedeploy_deployment_config/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CodeDeploy Deployment Configuration with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CodeDeploy deployment configuration attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_codedeploy_deployment_config(name, attributes = {})
        # Validate attributes using dry-struct
        config_attrs = Types::CodeDeployDeploymentConfigAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_codedeploy_deployment_config, name) do
          # Basic configuration
          deployment_config_name config_attrs.deployment_config_name
          compute_platform config_attrs.compute_platform
          
          # Minimum healthy hosts (for Server platform)
          if config_attrs.server_platform?
            minimum_healthy_hosts do
              type config_attrs.minimum_healthy_hosts[:type]
              value config_attrs.minimum_healthy_hosts[:value]
            end
          end
          
          # Traffic routing config (for Lambda/ECS platforms)
          if config_attrs.traffic_routing_config[:type]
            traffic_routing_config do
              type config_attrs.traffic_routing_config[:type]
              
              if config_attrs.traffic_routing_config[:time_based_canary]
                time_based_canary do
                  canary_percentage config_attrs.traffic_routing_config[:time_based_canary][:canary_percentage]
                  canary_interval config_attrs.traffic_routing_config[:time_based_canary][:canary_interval]
                end
              end
              
              if config_attrs.traffic_routing_config[:time_based_linear]
                time_based_linear do
                  linear_percentage config_attrs.traffic_routing_config[:time_based_linear][:linear_percentage]
                  linear_interval config_attrs.traffic_routing_config[:time_based_linear][:linear_interval]
                end
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_codedeploy_deployment_config',
          name: name,
          resource_attributes: config_attrs.to_h,
          outputs: {
            id: "${aws_codedeploy_deployment_config.#{name}.id}",
            deployment_config_id: "${aws_codedeploy_deployment_config.#{name}.deployment_config_id}",
            deployment_config_name: "${aws_codedeploy_deployment_config.#{name}.deployment_config_name}"
          },
          computed: {
            server_platform: config_attrs.server_platform?,
            lambda_platform: config_attrs.lambda_platform?,
            ecs_platform: config_attrs.ecs_platform?,
            uses_traffic_routing: config_attrs.uses_traffic_routing?,
            canary_deployment: config_attrs.canary_deployment?,
            linear_deployment: config_attrs.linear_deployment?,
            all_at_once_deployment: config_attrs.all_at_once_deployment?,
            deployment_description: config_attrs.deployment_description
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)