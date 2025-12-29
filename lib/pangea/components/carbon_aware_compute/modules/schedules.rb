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

module Pangea
  module Components
    module CarbonAwareCompute
      # EventBridge schedule resources for Carbon Aware Compute
      module Schedules
        def create_scheduler_rule(input, function, role)
          aws_eventbridge_scheduler_schedule(:"#{input.name}-scheduler-rule", {
            flexible_time_window: {
              mode: "FLEXIBLE",
              maximum_window_in_minutes: 15
            },
            schedule_expression: "rate(5 minutes)",
            target: {
              arn: function.arn,
              role_arn: role.arn,
              retry_policy: { maximum_retry_attempts: 2 }
            },
            tags: component_tags(input)
          })
        end

        def create_carbon_check_rule(input, function, role)
          aws_eventbridge_scheduler_schedule(:"#{input.name}-carbon-check-rule", {
            flexible_time_window: { mode: "OFF" },
            schedule_expression: "rate(15 minutes)",
            target: {
              arn: function.arn,
              role_arn: role.arn
            },
            tags: component_tags(input)
          })
        end
      end
    end
  end
end
