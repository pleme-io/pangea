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
        # Deployment configuration attributes for CodeDeploy deployment groups
        class DeploymentAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Auto rollback configuration
          attribute :auto_rollback_configuration, Resources::Types::Hash.schema(
            enabled?: Resources::Types::Bool.optional,
            events?: Resources::Types::Array.of(
              Resources::Types::String.enum('DEPLOYMENT_FAILURE', 'DEPLOYMENT_STOP_ON_ALARM', 'DEPLOYMENT_STOP_ON_REQUEST')
            ).optional
          ).default({}.freeze)

          # Alarm configuration
          attribute :alarm_configuration, Resources::Types::Hash.schema(
            alarms?: Resources::Types::Array.of(Resources::Types::String).optional,
            enabled?: Resources::Types::Bool.optional,
            ignore_poll_alarm_failure?: Resources::Types::Bool.optional
          ).default({}.freeze)

          # Blue-green deployment configuration
          attribute :blue_green_deployment_config, Resources::Types::Hash.schema(
            terminate_blue_instances_on_deployment_success?: Resources::Types::Hash.schema(
              action?: Resources::Types::String.enum('TERMINATE', 'KEEP_ALIVE').optional,
              termination_wait_time_in_minutes?: Resources::Types::Integer.constrained(gteq: 0, lteq: 2880).optional
            ).optional,
            deployment_ready_option?: Resources::Types::Hash.schema(
              action_on_timeout?: Resources::Types::String.enum('CONTINUE_DEPLOYMENT', 'STOP_DEPLOYMENT').optional
            ).optional,
            green_fleet_provisioning_option?: Resources::Types::Hash.schema(
              action?: Resources::Types::String.enum('DISCOVER_EXISTING', 'COPY_AUTO_SCALING_GROUP').optional
            ).optional
          ).default({}.freeze)

          # Deployment style
          attribute :deployment_style, Resources::Types::Hash.schema(
            deployment_type?: Resources::Types::String.enum('IN_PLACE', 'BLUE_GREEN').optional,
            deployment_option?: Resources::Types::String.enum('WITH_TRAFFIC_CONTROL', 'WITHOUT_TRAFFIC_CONTROL').optional
          ).default({}.freeze)
        end
      end
    end
  end
end
