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
  module Resources
    module AWS
      module Types
        module GlueTriggerTypes
          module HelpersModules
            # Instance methods for AWS Glue Trigger attributes
            module InstanceMethods
              # Check if trigger is scheduled
              def is_scheduled?
                type == "SCHEDULED"
              end

              # Check if trigger is conditional
              def is_conditional?
                type == "CONDITIONAL"
              end

              # Check if trigger is on-demand
              def is_on_demand?
                type == "ON_DEMAND"
              end

              # Check if trigger is part of workflow
              def is_workflow_trigger?
                !workflow_name.nil?
              end

              # Get job actions
              def job_actions
                actions.select { |action| action[:job_name] }
              end

              # Get crawler actions
              def crawler_actions
                actions.select { |action| action[:crawler_name] }
              end

              # Get total action count
              def total_actions
                actions.size
              end

              # Get condition count for conditional triggers
              def condition_count
                return 0 unless is_conditional?
                predicate&.dig(:conditions)&.size || 0
              end

              # Get schedule frequency (for scheduled triggers)
              def schedule_frequency
                return nil unless is_scheduled?
                return nil unless schedule

                case schedule
                when /rate\((\d+)\s+(minute|minutes)\)/
                  { type: "minutes", value: $1.to_i }
                when /rate\((\d+)\s+(hour|hours)\)/
                  { type: "hours", value: $1.to_i }
                when /rate\((\d+)\s+(day|days)\)/
                  { type: "days", value: $1.to_i }
                when /cron\(/
                  { type: "cron", expression: schedule }
                else
                  { type: "unknown", expression: schedule }
                end
              end

              # Estimate trigger execution frequency per day
              def estimated_executions_per_day
                return 0 unless is_scheduled?

                freq = schedule_frequency
                return 1 unless freq

                case freq[:type]
                when "minutes"
                  (24 * 60) / freq[:value]
                when "hours"
                  24 / freq[:value]
                when "days"
                  1.0 / freq[:value]
                when "cron"
                  # Complex cron expressions are hard to calculate
                  1
                else
                  1
                end
              end

              # Check if trigger configuration is optimal
              def configuration_warnings
                warnings = []

                if is_scheduled? && estimated_executions_per_day > 1440
                  warnings << "Very frequent scheduling (>1440/day) may impact costs and performance"
                end

                if is_conditional? && condition_count > 10
                  warnings << "Large number of conditions may impact trigger evaluation performance"
                end

                if total_actions > 20
                  warnings << "Large number of actions may impact trigger execution time"
                end

                if is_scheduled? && !start_on_creation
                  warnings << "Consider setting start_on_creation=true for immediate scheduling"
                end

                job_actions.each do |action|
                  unless action[:timeout]
                    warnings << "Consider setting timeout for job actions to prevent long-running jobs"
                  end
                end

                warnings
              end
            end
          end
        end
      end
    end
  end
end
