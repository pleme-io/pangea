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
require 'pangea/resources/aws_cloudwatch_composite_alarm/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudWatch Composite Alarm with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudWatch Composite Alarm attributes
      # @option attributes [String] :alarm_name The name for the composite alarm
      # @option attributes [String] :alarm_rule The expression that specifies which alarms to monitor
      # @option attributes [String] :alarm_description Description for the composite alarm
      # @option attributes [Boolean] :actions_enabled Whether actions should be executed
      # @option attributes [Hash] :actions_suppressor Suppressor configuration
      # @option attributes [Array<String>] :alarm_actions Actions when alarm transitions to ALARM
      # @option attributes [Array<String>] :ok_actions Actions when alarm transitions to OK
      # @option attributes [Array<String>] :insufficient_data_actions Actions when alarm has insufficient data
      # @option attributes [Hash] :tags Tags to apply to the alarm
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Simple composite alarm
      #   composite = aws_cloudwatch_composite_alarm(:critical_failures, {
      #     alarm_name: "critical-system-failures",
      #     alarm_description: "Triggers when multiple critical alarms are in ALARM state",
      #     alarm_rule: "ALARM(high-cpu-alarm) AND ALARM(high-memory-alarm)",
      #     alarm_actions: [sns_topic.arn]
      #   })
      #
      # @example Complex composite alarm with suppressor
      #   composite = aws_cloudwatch_composite_alarm(:app_health, {
      #     alarm_name: "application-health-composite",
      #     alarm_rule: "(ALARM(api-errors) OR ALARM(db-errors)) AND NOT ALARM(maintenance-window)",
      #     actions_suppressor: {
      #       alarm: ref(:aws_cloudwatch_metric_alarm, :maintenance_window, :alarm_name),
      #       extension_period: 300
      #     },
      #     alarm_actions: [pagerduty_topic.arn, slack_topic.arn]
      #   })
      #
      # @example Multi-condition composite alarm
      #   composite = aws_cloudwatch_composite_alarm(:service_degraded, {
      #     alarm_name: "service-degradation-detector",
      #     alarm_rule: <<~RULE.strip,
      #       (ALARM(latency-p99) AND ALARM(error-rate)) OR 
      #       (ALARM(queue-depth) AND ALARM(processing-lag)) OR
      #       ALARM(database-connections)
      #     RULE
      #     alarm_actions: [incident_topic.arn],
      #     ok_actions: [recovery_topic.arn]
      #   })
      def aws_cloudwatch_composite_alarm(name, attributes = {})
        # Validate attributes using dry-struct
        alarm_attrs = Types::Types::CloudWatchCompositeAlarmAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudwatch_composite_alarm, name) do
          # Required attributes
          alarm_name alarm_attrs.alarm_name
          alarm_rule alarm_attrs.alarm_rule
          
          # Optional attributes
          alarm_description alarm_attrs.alarm_description if alarm_attrs.alarm_description
          actions_enabled alarm_attrs.actions_enabled
          
          # Actions suppressor
          if alarm_attrs.actions_suppressor
            actions_suppressor do
              alarm alarm_attrs.actions_suppressor[:alarm]
              extension_period alarm_attrs.actions_suppressor[:extension_period] if alarm_attrs.actions_suppressor[:extension_period]
              wait_period alarm_attrs.actions_suppressor[:wait_period] if alarm_attrs.actions_suppressor[:wait_period]
            end
          end
          
          # Actions
          alarm_actions alarm_attrs.alarm_actions if alarm_attrs.alarm_actions.any?
          ok_actions alarm_attrs.ok_actions if alarm_attrs.ok_actions.any?
          insufficient_data_actions alarm_attrs.insufficient_data_actions if alarm_attrs.insufficient_data_actions.any?
          
          # Apply tags if present
          if alarm_attrs.tags.any?
            tags do
              alarm_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cloudwatch_composite_alarm',
          name: name,
          resource_attributes: alarm_attrs.to_h,
          outputs: {
            id: "${aws_cloudwatch_composite_alarm.#{name}.id}",
            arn: "${aws_cloudwatch_composite_alarm.#{name}.arn}",
            alarm_name: "${aws_cloudwatch_composite_alarm.#{name}.alarm_name}",
            alarm_description: "${aws_cloudwatch_composite_alarm.#{name}.alarm_description}",
            alarm_rule: "${aws_cloudwatch_composite_alarm.#{name}.alarm_rule}",
            actions_enabled: "${aws_cloudwatch_composite_alarm.#{name}.actions_enabled}"
          },
          computed_properties: {
            referenced_alarms: alarm_attrs.referenced_alarms,
            rule_complexity: alarm_attrs.rule_complexity,
            has_actions_suppressor: alarm_attrs.has_actions_suppressor?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)