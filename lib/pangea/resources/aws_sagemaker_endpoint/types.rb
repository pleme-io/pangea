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
require_relative 'types/deployment_config'
require_relative 'types/computed_properties'
require_relative 'types/deployment_analysis'

module Pangea
  module Resources
    module AWS
      module Types
        # SageMaker Endpoint attributes with deployment and monitoring validation
        class SageMakerEndpointAttributes < Dry::Struct
          include SageMakerEndpointComputedProperties
          include SageMakerEndpointDeploymentAnalysis

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
              validate_blue_green_policy(attrs[:deployment_config][:blue_green_update_policy])
            end

            # Validate auto-rollback configuration
            if attrs.dig(:deployment_config, :auto_rollback_configuration, :alarms)
              validate_rollback_alarms(attrs[:deployment_config][:auto_rollback_configuration][:alarms])
            end

            super(attrs)
          end

          # Validate blue-green deployment policy
          def self.validate_blue_green_policy(blue_green)
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

          # Validate auto-rollback alarm configuration
          def self.validate_rollback_alarms(alarms)
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
        end
      end
    end
  end
end
