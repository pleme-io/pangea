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
        # CloudWatch Composite Alarm resource attributes with validation
        class CloudWatchCompositeAlarmAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :alarm_name, Resources::Types::String
          attribute :alarm_rule, Resources::Types::String
          
          # Optional attributes
          attribute :alarm_description, Resources::Types::String.optional.default(nil)
          attribute :actions_enabled, Resources::Types::Bool.default(true)
          attribute :actions_suppressor, Resources::Types::Hash.schema(
            alarm: Resources::Types::String,
            extension_period: Resources::Types::Integer.optional,
            wait_period: Resources::Types::Integer.optional
          ).optional.default(nil)
          
          # Alarm actions
          attribute :alarm_actions, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
          attribute :ok_actions, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
          attribute :insufficient_data_actions, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
          
          # Tags
          attribute :tags, Resources::Types::AwsTags
          
          # Validate alarm rule syntax (basic validation)
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate alarm_rule contains valid operators
            if attrs[:alarm_rule]
              rule = attrs[:alarm_rule].to_s
              unless rule.match?(/\b(ALARM|OK|INSUFFICIENT_DATA|TRUE|FALSE|AND|OR|NOT)\b/)
                raise Dry::Struct::Error, "alarm_rule must contain valid CloudWatch composite alarm operators"
              end
              
              # Basic parentheses matching
              open_parens = rule.count('(')
              close_parens = rule.count(')')
              if open_parens != close_parens
                raise Dry::Struct::Error, "alarm_rule has mismatched parentheses"
              end
            end
            
            # Validate actions_suppressor
            if attrs[:actions_suppressor]
              suppressor = attrs[:actions_suppressor]
              if suppressor[:extension_period] && suppressor[:wait_period]
                raise Dry::Struct::Error, "actions_suppressor cannot have both extension_period and wait_period"
              end
              
              unless suppressor[:extension_period] || suppressor[:wait_period]
                raise Dry::Struct::Error, "actions_suppressor must have either extension_period or wait_period"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def referenced_alarms
            # Extract alarm names from the rule
            alarm_rule.scan(/ALARM\(([^)]+)\)/).flatten.map(&:strip).map { |a| a.delete('"\'') }.uniq
          end
          
          def rule_complexity
            # Count logical operators to gauge complexity
            operators = alarm_rule.scan(/\b(AND|OR|NOT)\b/i).size
            case operators
            when 0 then :simple
            when 1..3 then :moderate
            else :complex
            end
          end
          
          def has_actions_suppressor?
            !actions_suppressor.nil?
          end
          
          def to_h
            hash = {
              alarm_name: alarm_name,
              alarm_rule: alarm_rule,
              actions_enabled: actions_enabled,
              tags: tags
            }
            
            # Optional attributes
            hash[:alarm_description] = alarm_description if alarm_description
            
            # Actions suppressor
            if actions_suppressor
              hash[:actions_suppressor] = {
                alarm: actions_suppressor[:alarm]
              }
              hash[:actions_suppressor][:extension_period] = actions_suppressor[:extension_period] if actions_suppressor[:extension_period]
              hash[:actions_suppressor][:wait_period] = actions_suppressor[:wait_period] if actions_suppressor[:wait_period]
            end
            
            # Actions
            hash[:alarm_actions] = alarm_actions if alarm_actions.any?
            hash[:ok_actions] = ok_actions if ok_actions.any?
            hash[:insufficient_data_actions] = insufficient_data_actions if insufficient_data_actions.any?
            
            hash.compact
          end
        end
      end
    end
  end
end