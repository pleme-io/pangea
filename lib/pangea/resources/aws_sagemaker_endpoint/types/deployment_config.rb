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

require 'dry-types'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        include Dry.Types()

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
      end
    end
  end
end
