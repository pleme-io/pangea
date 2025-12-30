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
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Event pattern validation for EventBridge rules
        EventPattern = Pangea::Resources::Types::String.constructor { |value|
          begin
            parsed = JSON.parse(value)

            unless parsed.is_a?(Hash)
              raise Dry::Types::ConstraintError, "Event pattern must be a JSON object"
            end

            allowed_keys = %w[source detail-type detail account time region version id resources]
            invalid_keys = parsed.keys - allowed_keys
            unless invalid_keys.empty?
              raise Dry::Types::ConstraintError, "Invalid event pattern keys: #{invalid_keys.join(', ')}"
            end

            value
          rescue JSON::ParserError => e
            raise Dry::Types::ConstraintError, "Event pattern must be valid JSON: #{e.message}"
          end
        }

        # Schedule expression validation for EventBridge rules
        ScheduleExpression = Pangea::Resources::Types::String.constructor { |value|
          if value.match?(/\Arate\(/)
            unless value.match?(/\Arate\((\d+)\s+(minute|minutes|hour|hours|day|days)\)\z/)
              raise Dry::Types::ConstraintError, "Invalid rate expression. Format: rate(value unit)"
            end

            match = value.match(/\Arate\((\d+)\s+(minute|minutes|hour|hours|day|days)\)\z/)
            number = match[1].to_i
            unit = match[2]

            case unit
            when 'minute', 'minutes'
              raise Dry::Types::ConstraintError, "Rate expression minimum is 1 minute" if number < 1
            when 'hour', 'hours'
              raise Dry::Types::ConstraintError, "Rate expression minimum is 1 hour" if number < 1
            when 'day', 'days'
              raise Dry::Types::ConstraintError, "Rate expression minimum is 1 day" if number < 1
            end

          elsif value.match?(/\Acron\(/)
            unless value.match?(/\Acron\([^)]+\)\z/)
              raise Dry::Types::ConstraintError, "Invalid cron expression format"
            end

            cron_match = value.match(/\Acron\(([^)]+)\)\z/)
            cron_fields = cron_match[1].split(/\s+/)

            unless cron_fields.length == 6
              raise Dry::Types::ConstraintError,
                    "Cron expression must have 6 fields: minute hour day month day-of-week year"
            end

          else
            raise Dry::Types::ConstraintError, "Schedule expression must start with 'rate(' or 'cron('"
          end

          value
        }
      end
    end
  end
end
