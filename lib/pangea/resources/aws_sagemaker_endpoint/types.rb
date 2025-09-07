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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # SageMaker Endpoint deployment configuration for updates
        SageMakerDeploymentConfig = Hash.schema(
          blue_green_update_policy?: Hash.schema(
            traffic_routing_configuration: Hash.schema(
              type: String.enum('ALL_AT_ONCE', 'CANARY', 'LINEAR'),
              wait_interval_in_seconds: Integer.constrained(gteq: 0, lteq: 3600),
              canary_size?: Hash.schema(
                type: String.enum('INSTANCE_COUNT', 'CAPACITY_PERCENT'),
                value: Integer.constrained(gteq: 1, lteq: 100)
              ).optional,
              linear_step_size?: Hash.schema(
                type: String.enum('INSTANCE_COUNT', 'CAPACITY_PERCENT'), 
                value: Integer.constrained(gteq: 1, lteq: 100)
              ).optional
            ),
            termination_wait_in_seconds?: Integer.constrained(gteq: 0, lteq: 3600).optional,
            maximum_execution_timeout_in_seconds?: Integer.constrained(gteq: 600, lteq: 14400).optional
          ).optional,
          auto_rollback_configuration?: Hash.schema(
            alarms?: Array.of(
              Hash.schema(
                alarm_name: String
              )
            ).optional
          ).optional
        )
        
        # SageMaker Endpoint attributes with deployment and monitoring validation
        class SageMakerEndpointAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :endpoint_name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 63,
            format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/
          )
          attribute :endpoint_config_name, Resources::Types::String
          
          # Optional attributes
          attribute :deployment_config, SageMakerDeploymentConfig.optional
          attribute :tags, Resources::Types::AwsTags
          
          # Custom validation for SageMaker Endpoint
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate endpoint name doesn't conflict with reserved names
            if attrs[:endpoint_name]
              reserved_keywords = ['sagemaker', 'aws', 'amazon', 'model', 'endpoint']
              if reserved_keywords.any? { |keyword| attrs[:endpoint_name].downcase.include?(keyword) }
                # This is a warning rather than error - many valid names might include these terms
              end
            end
            
            # Validate deployment configuration consistency
            if attrs[:deployment_config] && attrs[:deployment_config][:blue_green_update_policy]
              blue_green = attrs[:deployment_config][:blue_green_update_policy]
              traffic_config = blue_green[:traffic_routing_configuration]
              
              # Validate traffic routing configuration based on type
              case traffic_config[:type]
              when 'CANARY'
                unless traffic_config[:canary_size]
                  raise Dry::Struct::Error, "canary_size is required for CANARY traffic routing"
                end
              when 'LINEAR'
                unless traffic_config[:linear_step_size]
                  raise Dry::Struct::Error, "linear_step_size is required for LINEAR traffic routing"
                end
              when 'ALL_AT_ONCE'
                if traffic_config[:canary_size] || traffic_config[:linear_step_size]
                  raise Dry::Struct::Error, "canary_size and linear_step_size should not be specified for ALL_AT_ONCE routing"
                end
              end
              
              # Validate termination wait is reasonable
              if blue_green[:termination_wait_in_seconds] && blue_green[:termination_wait_in_seconds] > 3600
                raise Dry::Struct::Error, "termination_wait_in_seconds should not exceed 1 hour (3600 seconds)"
              end
              
              # Validate maximum execution timeout
              if blue_green[:maximum_execution_timeout_in_seconds]
                max_timeout = blue_green[:maximum_execution_timeout_in_seconds]
                if max_timeout < 600
                  raise Dry::Struct::Error, "maximum_execution_timeout_in_seconds must be at least 600 seconds (10 minutes)"
                end
              end
            end
            
            # Validate auto-rollback configuration
            if attrs.dig(:deployment_config, :auto_rollback_configuration, :alarms)
              alarms = attrs[:deployment_config][:auto_rollback_configuration][:alarms]
              if alarms.empty?
                raise Dry::Struct::Error, "At least one alarm must be specified for auto-rollback configuration"
              end
              
              # Validate alarm names are not empty
              alarms.each_with_index do |alarm, index|
                if alarm[:alarm_name].nil? || alarm[:alarm_name].strip.empty?
                  raise Dry::Struct::Error, "Alarm #{index}: alarm_name cannot be empty"
                end
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def estimated_monthly_cost
            # Endpoint itself has no cost, costs come from the underlying endpoint configuration
            # This would typically be calculated based on the endpoint config instances
            base_cost = 0.0
            
            # Add monitoring and logging overhead
            monitoring_cost = has_deployment_config? ? 5.0 : 0.0
            
            base_cost + monitoring_cost
          end
          
          def has_deployment_config?
            !deployment_config.nil?
          end
          
          def has_blue_green_deployment?
            deployment_config&.dig(:blue_green_update_policy) != nil
          end
          
          def has_auto_rollback?
            deployment_config&.dig(:auto_rollback_configuration) != nil
          end
          
          def supports_canary_deployments?
            return false unless has_blue_green_deployment?
            
            traffic_type = deployment_config.dig(:blue_green_update_policy, :traffic_routing_configuration, :type)
            traffic_type == 'CANARY'
          end
          
          def supports_linear_deployments?
            return false unless has_blue_green_deployment?
            
            traffic_type = deployment_config.dig(:blue_green_update_policy, :traffic_routing_configuration, :type)
            traffic_type == 'LINEAR'  
          end
          
          def deployment_strategy
            return 'all-at-once' unless has_blue_green_deployment?
            
            traffic_type = deployment_config.dig(:blue_green_update_policy, :traffic_routing_configuration, :type)
            traffic_type&.downcase&.gsub('_', '-') || 'all-at-once'
          end
          
          def traffic_routing_wait_time
            return 0 unless has_blue_green_deployment?
            
            deployment_config.dig(:blue_green_update_policy, :traffic_routing_configuration, :wait_interval_in_seconds) || 0
          end
          
          def termination_wait_time
            return 0 unless has_blue_green_deployment?
            
            deployment_config.dig(:blue_green_update_policy, :termination_wait_in_seconds) || 0
          end
          
          def max_deployment_timeout
            return 3600 unless has_blue_green_deployment? # Default 1 hour
            
            deployment_config.dig(:blue_green_update_policy, :maximum_execution_timeout_in_seconds) || 3600
          end
          
          def rollback_alarm_count
            return 0 unless has_auto_rollback?
            
            deployment_config.dig(:auto_rollback_configuration, :alarms)&.size || 0
          end
          
          def rollback_alarm_names
            return [] unless has_auto_rollback?
            
            alarms = deployment_config.dig(:auto_rollback_configuration, :alarms) || []
            alarms.map { |alarm| alarm[:alarm_name] }
          end
          
          # Deployment capability analysis
          def deployment_capabilities
            {
              strategy: deployment_strategy,
              supports_canary: supports_canary_deployments?,
              supports_linear: supports_linear_deployments?,
              supports_auto_rollback: has_auto_rollback?,
              traffic_wait_time: traffic_routing_wait_time,
              termination_wait_time: termination_wait_time,
              max_timeout: max_deployment_timeout,
              rollback_alarms: rollback_alarm_count
            }
          end
          
          # Canary deployment configuration
          def canary_configuration
            return nil unless supports_canary_deployments?
            
            canary_size = deployment_config.dig(:blue_green_update_policy, :traffic_routing_configuration, :canary_size)
            return nil unless canary_size
            
            {
              type: canary_size[:type],
              value: canary_size[:value],
              unit: canary_size[:type] == 'INSTANCE_COUNT' ? 'instances' : 'percent'
            }
          end
          
          # Linear deployment configuration
          def linear_configuration
            return nil unless supports_linear_deployments?
            
            linear_step = deployment_config.dig(:blue_green_update_policy, :traffic_routing_configuration, :linear_step_size)
            return nil unless linear_step
            
            {
              type: linear_step[:type],
              value: linear_step[:value],
              unit: linear_step[:type] == 'INSTANCE_COUNT' ? 'instances' : 'percent'
            }
          end
          
          # Security and operational assessment
          def operational_score
            score = 0
            score += 30 if has_blue_green_deployment?
            score += 25 if has_auto_rollback?
            score += 20 if supports_canary_deployments? || supports_linear_deployments?
            score += 15 if rollback_alarm_count >= 2 # Multiple monitoring points
            score += 10 if traffic_routing_wait_time > 0 # Allows monitoring before full deployment
            
            [score, 100].min
          end
          
          def operational_status
            issues = []
            issues << "No blue-green deployment strategy configured" unless has_blue_green_deployment?
            issues << "No auto-rollback configuration" unless has_auto_rollback?
            issues << "Immediate traffic switching without monitoring period" if has_blue_green_deployment? && traffic_routing_wait_time == 0
            issues << "No rollback monitoring alarms configured" if has_auto_rollback? && rollback_alarm_count == 0
            issues << "Single alarm for rollback - consider multiple metrics" if rollback_alarm_count == 1
            
            {
              status: issues.empty? ? 'optimal' : 'needs_improvement',
              issues: issues
            }
          end
          
          # Endpoint summary for monitoring and management
          def endpoint_summary
            {
              endpoint_name: endpoint_name,
              endpoint_config_name: endpoint_config_name,
              deployment_strategy: deployment_strategy,
              operational_score: operational_score,
              estimated_monthly_cost: estimated_monthly_cost,
              capabilities: deployment_capabilities,
              canary_config: canary_configuration,
              linear_config: linear_configuration,
              rollback_alarms: rollback_alarm_names
            }
          end
        end
      end
    end
  end
end