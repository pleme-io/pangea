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
        # Infrastructure attributes for CodeDeploy deployment groups
        class InfrastructureAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Auto Scaling Groups
          attribute :auto_scaling_groups, Resources::Types::Array.of(Resources::Types::String).default([].freeze)

          # Load balancer info
          attribute :load_balancer_info, Resources::Types::Hash.schema(
            elb_info?: Resources::Types::Array.of(
              Resources::Types::Hash.schema(name?: Resources::Types::String.optional)
            ).optional,
            target_group_info?: Resources::Types::Array.of(
              Resources::Types::Hash.schema(name?: Resources::Types::String.optional)
            ).optional,
            target_group_pair_info?: Resources::Types::Array.of(
              Resources::Types::Hash.schema(
                prod_traffic_route?: Resources::Types::Hash.schema(
                  listener_arns?: Resources::Types::Array.of(Resources::Types::String).optional
                ).optional,
                test_traffic_route?: Resources::Types::Hash.schema(
                  listener_arns?: Resources::Types::Array.of(Resources::Types::String).optional
                ).optional,
                target_groups?: Resources::Types::Array.of(
                  Resources::Types::Hash.schema(name?: Resources::Types::String.optional)
                ).optional
              )
            ).optional
          ).default({}.freeze)

          # ECS service configuration
          attribute :ecs_service, Resources::Types::Hash.schema(
            cluster_name?: Resources::Types::String.optional,
            service_name?: Resources::Types::String.optional
          ).default({}.freeze)

          # Trigger configurations
          attribute :trigger_configurations, Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              trigger_name: Resources::Types::String,
              trigger_target_arn: Resources::Types::String,
              trigger_events: Resources::Types::Array.of(
                Resources::Types::String.enum(
                  'DeploymentStart', 'DeploymentSuccess', 'DeploymentFailure',
                  'DeploymentStop', 'DeploymentRollback', 'DeploymentReady',
                  'InstanceStart', 'InstanceSuccess', 'InstanceFailure',
                  'InstanceReady'
                )
              )
            )
          ).default([].freeze)
        end
      end
    end
  end
end
