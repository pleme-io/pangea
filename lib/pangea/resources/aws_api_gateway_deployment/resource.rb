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


require 'pangea/resources/reference'
require 'pangea/resources/aws_api_gateway_deployment/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # AWS API Gateway Deployment resource function
      # Creates deployments and optionally stages for API configurations
      def aws_api_gateway_deployment(name, attributes = {})
        # Validate and coerce attributes
        deployment_attrs = AWS::Types::Types::ApiGatewayDeploymentAttributes.new(attributes)
        
        # Generate Terraform resource block
        resource(:aws_api_gateway_deployment, name) do
          rest_api_id deployment_attrs.rest_api_id
          
          # Optional stage creation
          if deployment_attrs.stage_name
            stage_name deployment_attrs.stage_name
          end
          
          if deployment_attrs.stage_description
            stage_description deployment_attrs.stage_description
          end
          
          # Description
          if deployment_attrs.description
            description deployment_attrs.description
          end
          
          # Stage variables
          if deployment_attrs.variables.any?
            variables do
              deployment_attrs.variables.each do |key, value|
                send(key.tr('-', '_'), value)
              end
            end
          end
          
          # Canary settings
          if deployment_attrs.canary_settings
            canary_settings do
              if deployment_attrs.canary_settings[:percent_traffic]
                percent_traffic deployment_attrs.canary_settings[:percent_traffic]
              end
              
              if deployment_attrs.canary_settings[:stage_variable_overrides]
                stage_variable_overrides do
                  deployment_attrs.canary_settings[:stage_variable_overrides].each do |key, value|
                    send(key.tr('-', '_'), value)
                  end
                end
              end
              
              if deployment_attrs.canary_settings.key?(:use_stage_cache)
                use_stage_cache deployment_attrs.canary_settings[:use_stage_cache]
              end
            end
          end
          
          # Triggers for redeployment
          if deployment_attrs.triggers.any?
            triggers do
              deployment_attrs.triggers.each do |key, value|
                send(key.tr('-', '_'), value)
              end
            end
          end
          
          # Lifecycle management
          lifecycle do
            create_before_destroy true
          end
        end
        
        # Create ResourceReference with outputs and computed properties
        ref = ResourceReference.new(
          type: 'aws_api_gateway_deployment',
          name: name,
          resource_attributes: deployment_attrs.to_h,
          outputs: {
            # Standard Terraform outputs
            id: "${aws_api_gateway_deployment.#{name}.id}",
            rest_api_id: "${aws_api_gateway_deployment.#{name}.rest_api_id}",
            stage_name: "${aws_api_gateway_deployment.#{name}.stage_name}",
            stage_description: "${aws_api_gateway_deployment.#{name}.stage_description}",
            description: "${aws_api_gateway_deployment.#{name}.description}",
            variables: "${aws_api_gateway_deployment.#{name}.variables}",
            canary_settings: "${aws_api_gateway_deployment.#{name}.canary_settings}",
            triggers: "${aws_api_gateway_deployment.#{name}.triggers}",
            invoke_url: "${aws_api_gateway_deployment.#{name}.invoke_url}",
            execution_arn: "${aws_api_gateway_deployment.#{name}.execution_arn}",
            created_date: "${aws_api_gateway_deployment.#{name}.created_date}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:creates_stage?) { deployment_attrs.creates_stage? }
        ref.define_singleton_method(:has_canary?) { deployment_attrs.has_canary? }
        ref.define_singleton_method(:canary_percentage) { deployment_attrs.canary_percentage }
        ref.define_singleton_method(:has_stage_variables?) { deployment_attrs.has_stage_variables? }
        
        # Add convenience methods
        ref.define_singleton_method(:deployment_type) do
          if deployment_attrs.has_canary?
            if deployment_attrs.canary_percentage == 100.0
              'blue_green'
            elsif deployment_attrs.canary_percentage > 0.0
              'canary'
            else
              'standard'
            end
          else
            'standard'
          end
        end
        
        ref.define_singleton_method(:stage_url) do
          if deployment_attrs.creates_stage?
            "${aws_api_gateway_deployment.#{name}.invoke_url}"
          else
            nil
          end
        end
        
        ref.define_singleton_method(:canary_configuration) do
          if deployment_attrs.has_canary?
            {
              enabled: true,
              percent_traffic: deployment_attrs.canary_percentage,
              variable_overrides: deployment_attrs.canary_settings[:stage_variable_overrides] || {},
              use_stage_cache: deployment_attrs.canary_settings[:use_stage_cache]
            }
          else
            { enabled: false }
          end
        end
        
        ref.define_singleton_method(:stage_configuration) do
          config = {}
          config[:name] = deployment_attrs.stage_name if deployment_attrs.creates_stage?
          config[:description] = deployment_attrs.stage_description if deployment_attrs.stage_description
          config[:variables] = deployment_attrs.variables if deployment_attrs.has_stage_variables?
          config[:canary] = canary_configuration if deployment_attrs.has_canary?
          config
        end
        
        ref.define_singleton_method(:deployment_metadata) do
          {
            type: deployment_type,
            creates_stage: deployment_attrs.creates_stage?,
            has_canary: deployment_attrs.has_canary?,
            trigger_count: deployment_attrs.triggers.size,
            variable_count: deployment_attrs.variables.size,
            canary_enabled: deployment_attrs.has_canary?
          }
        end
        
        # Helper methods for common operations
        ref.define_singleton_method(:trigger_names) { deployment_attrs.triggers.keys }
        ref.define_singleton_method(:variable_names) { deployment_attrs.variables.keys }
        
        ref.define_singleton_method(:is_production_deployment?) do
          stage_name = deployment_attrs.stage_name
          stage_name && ['prod', 'production', 'live'].include?(stage_name.downcase)
        end
        
        ref.define_singleton_method(:is_development_deployment?) do
          stage_name = deployment_attrs.stage_name
          stage_name && ['dev', 'development', 'sandbox'].include?(stage_name.downcase)
        end
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)