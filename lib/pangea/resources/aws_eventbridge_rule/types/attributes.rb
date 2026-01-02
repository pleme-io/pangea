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
require_relative 'validators'
require_relative 'helpers'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS EventBridge Rule resources
        class EventbridgeRuleAttributes < Dry::Struct
          include EventbridgeRuleHelpers

          transform_keys(&:to_sym)

          # Rule name (required)
          attribute :name, Pangea::Resources::Types::String.constrained(format: /\A[a-zA-Z0-9._\-]{1,64}\z/)

          # Rule description
          attribute? :description, Pangea::Resources::Types::String.optional.constrained(max_size: 512)

          # Event bus name (defaults to "default")
          attribute :event_bus_name, Pangea::Resources::Types::String.default("default")

          # Rule state
          attribute :state, Pangea::Resources::Types::String.default("ENABLED").constrained(
            included_in: %w[ENABLED DISABLED]
          )

          # Event pattern (JSON) - mutually exclusive with schedule_expression
          attribute? :event_pattern, EventPattern.optional

          # Schedule expression - mutually exclusive with event_pattern
          attribute? :schedule_expression, ScheduleExpression.optional

          # Role ARN for rules that need to invoke targets
          attribute? :role_arn, Pangea::Resources::Types::String.optional.constrained(format: /\Aarn:aws:iam::/)

          # Tagging support
          attribute :tags, Pangea::Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            if attrs.event_pattern && attrs.schedule_expression
              raise Dry::Struct::Error, "Cannot specify both event_pattern and schedule_expression"
            end

            if !attrs.event_pattern && !attrs.schedule_expression
              raise Dry::Struct::Error, "Must specify either event_pattern or schedule_expression"
            end

            if attrs.role_arn && !attrs.role_arn.match?(/\Aarn:aws:iam::\d{12}:role\//)
              raise Dry::Struct::Error, "Invalid IAM role ARN format"
            end

            attrs
          end
        end
      end
    end
  end
end
