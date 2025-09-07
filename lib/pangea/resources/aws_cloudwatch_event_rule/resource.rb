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
require 'pangea/resources/aws_cloudwatch_event_rule/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudWatch Event Rule with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudWatch Event Rule attributes
      # @option attributes [String] :name The name of the rule
      # @option attributes [String] :name_prefix Alternative to name for generated names
      # @option attributes [String] :description Description of the rule
      # @option attributes [String] :event_bus_name The event bus to associate with (default: "default")
      # @option attributes [String] :event_pattern Event pattern in JSON format
      # @option attributes [String] :schedule_expression Schedule expression (rate or cron)
      # @option attributes [String] :state State of the rule (ENABLED or DISABLED)
      # @option attributes [String] :role_arn IAM role ARN for the rule
      # @option attributes [Boolean] :is_enabled Convenience attribute for state
      # @option attributes [Hash] :tags Tags to apply to the rule
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Schedule-based rule
      #   scheduled_rule = aws_cloudwatch_event_rule(:hourly_task, {
      #     name: "hourly-maintenance",
      #     description: "Triggers hourly maintenance tasks",
      #     schedule_expression: "rate(1 hour)"
      #   })
      #
      # @example Event pattern rule
      #   ec2_rule = aws_cloudwatch_event_rule(:ec2_state_changes, {
      #     name: "ec2-instance-state-changes",
      #     description: "Captures EC2 instance state changes",
      #     event_pattern: jsonencode({
      #       source: ["aws.ec2"],
      #       "detail-type": ["EC2 Instance State-change Notification"],
      #       detail: {
      #         state: ["running", "stopped", "terminated"]
      #       }
      #     })
      #   })
      #
      # @example Custom event bus rule
      #   custom_rule = aws_cloudwatch_event_rule(:app_events, {
      #     name: "application-events",
      #     event_bus_name: custom_event_bus.name,
      #     event_pattern: jsonencode({
      #       source: ["myapp.orders"],
      #       "detail-type": ["Order Placed", "Order Cancelled"],
      #       detail: {
      #         value: [{ numeric: [">", 100] }]
      #       }
      #     })
      #   })
      def aws_cloudwatch_event_rule(name, attributes = {})
        # Validate attributes using dry-struct
        rule_attrs = Types::Types::CloudWatchEventRuleAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudwatch_event_rule, name) do
          # Name configuration
          if rule_attrs.name
            name rule_attrs.name
          elsif rule_attrs.name_prefix
            name_prefix rule_attrs.name_prefix
          end
          
          # Optional description
          description rule_attrs.description if rule_attrs.description
          
          # Event bus
          event_bus_name rule_attrs.event_bus_name if rule_attrs.event_bus_name != 'default'
          
          # Rule pattern - either event pattern or schedule
          event_pattern rule_attrs.event_pattern if rule_attrs.event_pattern
          schedule_expression rule_attrs.schedule_expression if rule_attrs.schedule_expression
          
          # State
          state rule_attrs.state
          
          # Optional role
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
        ResourceReference.new(
          type: 'aws_cloudwatch_event_rule',
          name: name,
          resource_attributes: rule_attrs.to_h,
          outputs: {
            id: "${aws_cloudwatch_event_rule.#{name}.id}",
            arn: "${aws_cloudwatch_event_rule.#{name}.arn}",
            name: "${aws_cloudwatch_event_rule.#{name}.name}",
            description: "${aws_cloudwatch_event_rule.#{name}.description}",
            event_bus_name: "${aws_cloudwatch_event_rule.#{name}.event_bus_name}",
            event_pattern: "${aws_cloudwatch_event_rule.#{name}.event_pattern}",
            schedule_expression: "${aws_cloudwatch_event_rule.#{name}.schedule_expression}",
            state: "${aws_cloudwatch_event_rule.#{name}.state}",
            role_arn: "${aws_cloudwatch_event_rule.#{name}.role_arn}"
          },
          computed_properties: {
            rule_type: rule_attrs.rule_type,
            schedule_type: rule_attrs.schedule_type,
            event_sources: rule_attrs.event_sources,
            event_detail_types: rule_attrs.event_detail_types,
            is_custom_event_bus: rule_attrs.is_custom_event_bus?,
            requires_role: rule_attrs.requires_role?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)