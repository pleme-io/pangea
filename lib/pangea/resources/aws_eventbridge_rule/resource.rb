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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_eventbridge_rule/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EventBridge Rule with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] EventBridge rule attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_eventbridge_rule(name, attributes = {})
        # Validate attributes using dry-struct
        rule_attrs = Types::Types::EventbridgeRuleAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudwatch_event_rule, name) do
          rule_name rule_attrs.name
          description rule_attrs.description if rule_attrs.description
          event_bus_name rule_attrs.event_bus_name
          state rule_attrs.state
          
          # Event pattern (mutually exclusive with schedule)
          event_pattern rule_attrs.event_pattern if rule_attrs.event_pattern
          
          # Schedule expression (mutually exclusive with event pattern)
          schedule_expression rule_attrs.schedule_expression if rule_attrs.schedule_expression
          
          # Role ARN for target invocations
          role_arn rule_attrs.role_arn if rule_attrs.role_arn

          # Apply tags if present
          if rule_attrs.tags.any?
            tags do
              rule_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ref = ResourceReference.new(
          type: 'aws_cloudwatch_event_rule',
          name: name,
          resource_attributes: rule_attrs.to_h,
          outputs: {
            id: "${aws_cloudwatch_event_rule.#{name}.id}",
            arn: "${aws_cloudwatch_event_rule.#{name}.arn}",
            name: "${aws_cloudwatch_event_rule.#{name}.name}",
            event_bus_name: "${aws_cloudwatch_event_rule.#{name}.event_bus_name}",
            state: "${aws_cloudwatch_event_rule.#{name}.state}",
            tags_all: "${aws_cloudwatch_event_rule.#{name}.tags_all}"
          }
        )
        
        # Add computed properties as singleton methods
        ref.define_singleton_method(:is_enabled?) { rule_attrs.is_enabled? }
        ref.define_singleton_method(:is_disabled?) { rule_attrs.is_disabled? }
        ref.define_singleton_method(:is_scheduled?) { rule_attrs.is_scheduled? }
        ref.define_singleton_method(:is_event_driven?) { rule_attrs.is_event_driven? }
        ref.define_singleton_method(:rule_type) { rule_attrs.rule_type }
        ref.define_singleton_method(:uses_default_bus?) { rule_attrs.uses_default_bus? }
        ref.define_singleton_method(:uses_custom_bus?) { rule_attrs.uses_custom_bus? }
        ref.define_singleton_method(:has_role?) { rule_attrs.has_role? }
        ref.define_singleton_method(:parsed_event_pattern) { rule_attrs.parsed_event_pattern }
        ref.define_singleton_method(:schedule_frequency) { rule_attrs.schedule_frequency }
        ref.define_singleton_method(:estimated_monthly_cost) { rule_attrs.estimated_monthly_cost }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)