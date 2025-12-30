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

require 'json'

module Pangea
  module Resources
    module AWS
      module Types
        # Helper methods for EventbridgeRuleAttributes
        module EventbridgeRuleHelpers
          def is_enabled?
            state == "ENABLED"
          end

          def is_disabled?
            state == "DISABLED"
          end

          def is_scheduled?
            !schedule_expression.nil?
          end

          def is_event_driven?
            !event_pattern.nil?
          end

          def rule_type
            return "scheduled" if is_scheduled?
            return "event_pattern" if is_event_driven?

            "unknown"
          end

          def uses_default_bus?
            event_bus_name == "default"
          end

          def uses_custom_bus?
            !uses_default_bus?
          end

          def has_role?
            !role_arn.nil?
          end

          def parsed_event_pattern
            return nil unless event_pattern

            JSON.parse(event_pattern)
          rescue JSON::ParserError
            nil
          end

          def schedule_frequency
            return nil unless schedule_expression

            if schedule_expression.start_with?("rate(")
              match = schedule_expression.match(/\Arate\((\d+)\s+(minute|minutes|hour|hours|day|days)\)\z/)
              return "Every #{match[1]} #{match[2]}" if match
            elsif schedule_expression.start_with?("cron(")
              return "Custom cron schedule"
            end

            "Unknown schedule"
          end

          def estimated_monthly_cost
            if is_scheduled?
              case schedule_frequency
              when /minute/
                "~$5-15/month (high frequency)"
              when /hour/
                "~$1-5/month (hourly)"
              when /day/
                "~$0.10-1/month (daily)"
              else
                "~$1-10/month"
              end
            else
              "Variable based on event volume"
            end
          end
        end
      end
    end
  end
end
