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
      # Type-safe attributes for AWS CodeDeploy Deployment Configuration resources
      class CodeDeployDeploymentConfigAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Deployment config name (required)
        attribute :deployment_config_name, Resources::Types::String.constrained(
          format: /\A[a-zA-Z0-9._-]+\z/,
          min_size: 1,
          max_size: 100
        )

        # Compute platform
        attribute :compute_platform, Resources::Types::String.enum('Server', 'Lambda', 'ECS').default('Server')

        # Minimum healthy hosts (for Server platform)
        attribute :minimum_healthy_hosts, Resources::Types::Hash.schema(
          type: Resources::Types::String.enum('HOST_COUNT', 'FLEET_PERCENT'),
          value: Resources::Types::Integer.constrained(gteq: 0)
        ).default({ type: 'FLEET_PERCENT', value: 75 })

        # Traffic routing config (for Lambda/ECS platforms)
        attribute :traffic_routing_config, Resources::Types::Hash.schema(
          type?: Resources::Types::String.enum('TimeBasedCanary', 'TimeBasedLinear', 'AllAtOnceTrafficShift').optional,
          time_based_canary?: Resources::Types::Hash.schema(
            canary_percentage: Resources::Types::Integer.constrained(gteq: 0, lteq: 100),
            canary_interval: Resources::Types::Integer.constrained(gteq: 0)
          ).optional,
          time_based_linear?: Resources::Types::Hash.schema(
            linear_percentage: Resources::Types::Integer.constrained(gteq: 0, lteq: 100),
            linear_interval: Resources::Types::Integer.constrained(gteq: 0)
          ).optional
        ).default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate minimum healthy hosts for Server platform
          if attrs.compute_platform == 'Server'
            if attrs.minimum_healthy_hosts[:type] == 'FLEET_PERCENT' && attrs.minimum_healthy_hosts[:value] > 100
              raise Dry::Struct::Error, "Fleet percent cannot exceed 100"
            end
          end

          # Validate traffic routing for Lambda/ECS
          if attrs.compute_platform != 'Server' && attrs.minimum_healthy_hosts != { type: 'FLEET_PERCENT', value: 75 }
            raise Dry::Struct::Error, "minimum_healthy_hosts is only valid for Server platform"
          end

          if attrs.compute_platform == 'Server' && attrs.traffic_routing_config.any?
            raise Dry::Struct::Error, "traffic_routing_config is only valid for Lambda/ECS platforms"
          end

          # Validate traffic routing configuration
          if attrs.traffic_routing_config[:type] == 'TimeBasedCanary' && !attrs.traffic_routing_config[:time_based_canary]
            raise Dry::Struct::Error, "TimeBasedCanary requires time_based_canary configuration"
          end

          if attrs.traffic_routing_config[:type] == 'TimeBasedLinear' && !attrs.traffic_routing_config[:time_based_linear]
            raise Dry::Struct::Error, "TimeBasedLinear requires time_based_linear configuration"
          end

          attrs
        end

        # Helper methods
        def server_platform?
          compute_platform == 'Server'
        end

        def lambda_platform?
          compute_platform == 'Lambda'
        end

        def ecs_platform?
          compute_platform == 'ECS'
        end

        def uses_traffic_routing?
          traffic_routing_config[:type].present?
        end

        def canary_deployment?
          traffic_routing_config[:type] == 'TimeBasedCanary'
        end

        def linear_deployment?
          traffic_routing_config[:type] == 'TimeBasedLinear'
        end

        def all_at_once_deployment?
          traffic_routing_config[:type] == 'AllAtOnceTrafficShift'
        end

        def deployment_description
          if server_platform?
            case minimum_healthy_hosts[:type]
            when 'HOST_COUNT'
              "Keep #{minimum_healthy_hosts[:value]} hosts healthy"
            when 'FLEET_PERCENT'
              "Keep #{minimum_healthy_hosts[:value]}% of fleet healthy"
            end
          elsif canary_deployment?
            canary = traffic_routing_config[:time_based_canary]
            "Canary: #{canary[:canary_percentage]}% for #{canary[:canary_interval]} minutes"
          elsif linear_deployment?
            linear = traffic_routing_config[:time_based_linear]
            "Linear: #{linear[:linear_percentage]}% every #{linear[:linear_interval]} minutes"
          elsif all_at_once_deployment?
            "All at once traffic shift"
          else
            "Default configuration"
          end
        end
      end
    end
      end
    end
  end
end