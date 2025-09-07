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

module Pangea
  module Resources
    module AWS
      module AppConfig
        # AWS AppConfig Deployment Strategy resource
        # Defines how AppConfig deploys configuration changes to targets.
        # Deployment strategies control rollout speed, monitoring, and rollback behavior.
        module DeploymentStrategy
          # Creates an AWS AppConfig Deployment Strategy
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the deployment strategy
          # @option attributes [String] :name Name of the deployment strategy (required)
          # @option attributes [String] :description Description of the strategy
          # @option attributes [Integer] :deployment_duration_in_minutes Total deployment time (required)
          # @option attributes [Integer] :final_bake_time_in_minutes Bake time after deployment
          # @option attributes [Float] :growth_factor Percentage to deploy per interval (required)
          # @option attributes [String] :growth_type Growth pattern (LINEAR or EXPONENTIAL)
          # @option attributes [String] :replicate_to Where to replicate (NONE or SSM_DOCUMENT)
          # @option attributes [Hash] :tags Tags to apply to the deployment strategy
          #
          # @example Conservative production deployment strategy
          #   prod_strategy = aws_appconfig_deployment_strategy(:conservative_prod, {
          #     name: "ConservativeProduction",
          #     description: "Slow rollout with extended bake time for production environments",
          #     deployment_duration_in_minutes: 60,
          #     final_bake_time_in_minutes: 30,
          #     growth_factor: 10.0,
          #     growth_type: "LINEAR",
          #     replicate_to: "NONE",
          #     tags: {
          #       "Environment" => "Production",
          #       "RolloutType" => "Conservative"
          #     }
          #   })
          #
          # @example Fast development deployment strategy
          #   dev_strategy = aws_appconfig_deployment_strategy(:fast_dev, {
          #     name: "FastDevelopment",
          #     description: "Immediate deployment for development environments",
          #     deployment_duration_in_minutes: 1,
          #     final_bake_time_in_minutes: 0,
          #     growth_factor: 100.0,
          #     growth_type: "EXPONENTIAL",
          #     replicate_to: "NONE",
          #     tags: {
          #       "Environment" => "Development",
          #       "RolloutType" => "Fast"
          #     }
          #   })
          #
          # @return [ResourceReference] The deployment strategy resource reference
          def aws_appconfig_deployment_strategy(name, attributes = {})
            resource(:aws_appconfig_deployment_strategy, name) do
              name attributes[:name] if attributes[:name]
              description attributes[:description] if attributes[:description]
              deployment_duration_in_minutes attributes[:deployment_duration_in_minutes] if attributes[:deployment_duration_in_minutes]
              final_bake_time_in_minutes attributes[:final_bake_time_in_minutes] if attributes[:final_bake_time_in_minutes]
              growth_factor attributes[:growth_factor] if attributes[:growth_factor]
              growth_type attributes[:growth_type] if attributes[:growth_type]
              replicate_to attributes[:replicate_to] if attributes[:replicate_to]
              tags attributes[:tags] if attributes[:tags]
            end
            
            ResourceReference.new(
              type: 'aws_appconfig_deployment_strategy',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_appconfig_deployment_strategy.#{name}.id}",
                arn: "${aws_appconfig_deployment_strategy.#{name}.arn}"
              },
              computed_properties: {
                is_immediate: attributes[:deployment_duration_in_minutes] <= 1,
                is_conservative: attributes[:growth_factor] && attributes[:growth_factor] <= 20,
                has_bake_time: attributes[:final_bake_time_in_minutes] && attributes[:final_bake_time_in_minutes] > 0,
                growth_pattern: attributes[:growth_type]&.downcase&.to_sym
              }
            )
          end
        end
      end
    end
  end
end