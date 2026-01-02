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
    module SpotInstanceCarbonOptimizer
      # EventBridge schedule and rule creation methods
      module Schedules
        def create_optimization_schedule(input, optimizer_function)
          aws_eventbridge_scheduler_schedule(:"#{input.name}-optimization-schedule", {
            flexible_time_window: {
              mode: "FLEXIBLE",
              maximum_window_in_minutes: 5
            },
            schedule_expression: "rate(#{input.carbon_reporting_interval_minutes} minutes)",
            target: {
              arn: optimizer_function.arn,
              role_arn: ref(:aws_iam_role, :"#{input.name}-scheduler-role", :arn)
            },
            tags: input.tags.merge("Component" => "spot-carbon-optimizer")
          })
        end

        def create_carbon_check_schedule(input, monitor_function)
          aws_eventbridge_scheduler_schedule(:"#{input.name}-carbon-check-schedule", {
            flexible_time_window: {
              mode: "OFF"
            },
            schedule_expression: "rate(5 minutes)",
            target: {
              arn: monitor_function.arn,
              role_arn: ref(:aws_iam_role, :"#{input.name}-scheduler-role", :arn)
            },
            tags: input.tags.merge("Component" => "spot-carbon-optimizer")
          })
        end

        def create_spot_interruption_rule(input, migration_function)
          aws_cloudwatch_event_rule(:"#{input.name}-spot-interruption-rule", {
            name: "#{input.name}-spot-interruption",
            description: "Trigger migration on spot interruption",
            event_pattern: JSON.pretty_generate({
              source: ["aws.ec2"],
              "detail-type": ["EC2 Spot Instance Interruption Warning"]
            }),
            targets: [{
              arn: migration_function.arn,
              id: "1"
            }],
            tags: input.tags
          })
        end
      end
    end
  end
end
