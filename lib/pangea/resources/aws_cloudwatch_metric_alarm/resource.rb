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
require 'pangea/resources/aws_cloudwatch_metric_alarm/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudWatch Metric Alarm with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudWatch Metric Alarm attributes
      # @option attributes [String] :alarm_name The name for the alarm
      # @option attributes [String] :comparison_operator How to compare the metric to the threshold
      # @option attributes [Integer] :evaluation_periods Number of periods to evaluate
      # @option attributes [String] :metric_name The metric name (traditional alarm)
      # @option attributes [String] :namespace The metric namespace (traditional alarm)
      # @option attributes [Integer] :period The period in seconds (traditional alarm)
      # @option attributes [String] :statistic The statistic to apply (traditional alarm)
      # @option attributes [Float] :threshold The threshold value
      # @option attributes [Array] :alarm_actions Actions to execute when alarm triggers
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Traditional metric alarm
      #   alarm = aws_cloudwatch_metric_alarm(:high_cpu, {
      #     alarm_name: "high-cpu-alarm",
      #     alarm_description: "Triggers when CPU exceeds 80%",
      #     comparison_operator: "GreaterThanThreshold",
      #     evaluation_periods: 2,
      #     metric_name: "CPUUtilization",
      #     namespace: "AWS/EC2",
      #     period: 300,
      #     statistic: "Average",
      #     threshold: 80.0,
      #     alarm_actions: [sns_topic.arn],
      #     dimensions: {
      #       InstanceId: instance.id
      #     }
      #   })
      #
      # @example Metric math alarm
      #   alarm = aws_cloudwatch_metric_alarm(:request_error_rate, {
      #     alarm_name: "high-error-rate",
      #     comparison_operator: "GreaterThanThreshold",
      #     evaluation_periods: 3,
      #     threshold: 1.0,
      #     metric_query: [
      #       {
      #         id: "e1",
      #         expression: "m2/m1*100",
      #         label: "Error rate",
      #         return_data: true
      #       },
      #       {
      #         id: "m1",
      #         metric: {
      #           metric_name: "RequestCount",
      #           namespace: "AWS/ApplicationELB",
      #           period: 60,
      #           stat: "Sum"
      #         }
      #       },
      #       {
      #         id: "m2",
      #         metric: {
      #           metric_name: "HTTPCode_Target_5XX_Count",
      #           namespace: "AWS/ApplicationELB",
      #           period: 60,
      #           stat: "Sum"
      #         }
      #       }
      #     ]
      #   })
      def aws_cloudwatch_metric_alarm(name, attributes = {})
        # Validate attributes using dry-struct
        alarm_attrs = AWS::Types::Types::CloudWatchMetricAlarmAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudwatch_metric_alarm, name) do
          # Common attributes
          alarm_name alarm_attrs.alarm_name if alarm_attrs.alarm_name
          alarm_description alarm_attrs.alarm_description if alarm_attrs.alarm_description
          comparison_operator alarm_attrs.comparison_operator
          evaluation_periods alarm_attrs.evaluation_periods
          actions_enabled alarm_attrs.actions_enabled
          treat_missing_data alarm_attrs.treat_missing_data
          datapoints_to_alarm alarm_attrs.datapoints_to_alarm if alarm_attrs.datapoints_to_alarm
          evaluate_low_sample_count_percentile alarm_attrs.evaluate_low_sample_count_percentile if alarm_attrs.evaluate_low_sample_count_percentile
          
          # Actions
          alarm_actions alarm_attrs.alarm_actions if alarm_attrs.alarm_actions.any?
          ok_actions alarm_attrs.ok_actions if alarm_attrs.ok_actions.any?
          insufficient_data_actions alarm_attrs.insufficient_data_actions if alarm_attrs.insufficient_data_actions.any?
          
          # Traditional alarm configuration
          if alarm_attrs.is_traditional_alarm?
            metric_name alarm_attrs.metric_name
            namespace alarm_attrs.namespace
            period alarm_attrs.period
            statistic alarm_attrs.statistic if alarm_attrs.statistic
            extended_statistic alarm_attrs.extended_statistic if alarm_attrs.extended_statistic
            unit alarm_attrs.unit if alarm_attrs.unit
            threshold alarm_attrs.threshold
            
            if alarm_attrs.dimensions.any?
              dimensions alarm_attrs.dimensions
            end
          end
          
          # Metric math alarm configuration
          if alarm_attrs.is_metric_math_alarm?
            threshold alarm_attrs.threshold if alarm_attrs.threshold
            threshold_metric_id alarm_attrs.threshold_metric_id if alarm_attrs.threshold_metric_id
            
            alarm_attrs.metric_query.each do |query|
              metric_query do
                id query.id
                expression query.expression if query.expression
                label query.label if query.label
                return_data query.return_data
                
                if query.metric
                  metric do
                    metric_name query.metric[:metric_name]
                    namespace query.metric[:namespace]
                    period query.metric[:period]
                    stat query.metric[:stat]
                    unit query.metric[:unit] if query.metric[:unit]
                    
                    if query.metric[:dimensions]
                      dimensions query.metric[:dimensions]
                    end
                  end
                end
              end
            end
          end
          
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
        ref = ResourceReference.new(
          type: 'aws_cloudwatch_metric_alarm',
          name: name,
          resource_attributes: alarm_attrs.to_h,
          outputs: {
            id: "${aws_cloudwatch_metric_alarm.#{name}.id}",
            arn: "${aws_cloudwatch_metric_alarm.#{name}.arn}",
            alarm_name: "${aws_cloudwatch_metric_alarm.#{name}.alarm_name}",
            alarm_description: "${aws_cloudwatch_metric_alarm.#{name}.alarm_description}",
            comparison_operator: "${aws_cloudwatch_metric_alarm.#{name}.comparison_operator}",
            evaluation_periods: "${aws_cloudwatch_metric_alarm.#{name}.evaluation_periods}",
            metric_name: "${aws_cloudwatch_metric_alarm.#{name}.metric_name}",
            namespace: "${aws_cloudwatch_metric_alarm.#{name}.namespace}",
            period: "${aws_cloudwatch_metric_alarm.#{name}.period}",
            statistic: "${aws_cloudwatch_metric_alarm.#{name}.statistic}",
            threshold: "${aws_cloudwatch_metric_alarm.#{name}.threshold}",
            treat_missing_data: "${aws_cloudwatch_metric_alarm.#{name}.treat_missing_data}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:is_metric_math_alarm?) { alarm_attrs.is_metric_math_alarm? }
        ref.define_singleton_method(:is_traditional_alarm?) { alarm_attrs.is_traditional_alarm? }
        ref.define_singleton_method(:uses_anomaly_detector?) { alarm_attrs.uses_anomaly_detector? }
        
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)