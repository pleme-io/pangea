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
require 'pangea/resources/aws_cloudwatch_log_metric_filter/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudWatch Log Metric Filter with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudWatch Log Metric Filter attributes
      # @option attributes [String] :name The name of the metric filter
      # @option attributes [String] :log_group_name The log group to associate the filter with
      # @option attributes [String] :pattern The filter pattern
      # @option attributes [Hash] :metric_transformation The metric transformation configuration
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Count error occurrences
      #   error_filter = aws_cloudwatch_log_metric_filter(:error_counter, {
      #     name: "application-errors",
      #     log_group_name: app_log_group.name,
      #     pattern: "[time, request_id, event_type=ERROR, ...]",
      #     metric_transformation: {
      #       name: "ErrorCount",
      #       namespace: "Application/Metrics",
      #       value: "1",
      #       default_value: 0
      #     }
      #   })
      #
      # @example Extract numeric values from logs
      #   latency_filter = aws_cloudwatch_log_metric_filter(:latency_tracker, {
      #     name: "api-latency",
      #     log_group_name: "/aws/lambda/api-handler",
      #     pattern: "[time, request_id, latency_ms, ...]",
      #     metric_transformation: {
      #       name: "APILatency",
      #       namespace: "API/Performance",
      #       value: "$latency_ms",
      #       unit: "Milliseconds"
      #     }
      #   })
      #
      # @example JSON log parsing with dimensions
      #   json_filter = aws_cloudwatch_log_metric_filter(:json_metrics, {
      #     name: "user-activity-metrics",
      #     log_group_name: ref(:aws_cloudwatch_log_group, :app_logs, :name),
      #     pattern: '{ $.eventType = "USER_ACTION" }',
      #     metric_transformation: {
      #       name: "UserActions",
      #       namespace: "Application/UserActivity",
      #       value: "1",
      #       default_value: 0,
      #       dimensions: {
      #         ActionType: "$.actionType",
      #         UserRole: "$.userRole"
      #       }
      #     }
      #   })
      def aws_cloudwatch_log_metric_filter(name, attributes = {})
        # Validate attributes using dry-struct
        filter_attrs = Types::Types::CloudWatchLogMetricFilterAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudwatch_log_metric_filter, name) do
          name filter_attrs.name
          log_group_name filter_attrs.log_group_name
          pattern filter_attrs.pattern
          
          # Metric transformation block
          metric_transformation do
            name filter_attrs.metric_transformation.name
            namespace filter_attrs.metric_transformation.namespace
            value filter_attrs.metric_transformation.value
            
            # Optional transformation attributes
            default_value filter_attrs.metric_transformation.default_value if filter_attrs.metric_transformation.default_value
            unit filter_attrs.metric_transformation.unit if filter_attrs.metric_transformation.unit
            
            # Dimensions if present
            if filter_attrs.metric_transformation.dimensions.any?
              dimensions filter_attrs.metric_transformation.dimensions
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cloudwatch_log_metric_filter',
          name: name,
          resource_attributes: filter_attrs.to_h,
          outputs: {
            id: "${aws_cloudwatch_log_metric_filter.#{name}.id}",
            name: "${aws_cloudwatch_log_metric_filter.#{name}.name}",
            log_group_name: "${aws_cloudwatch_log_metric_filter.#{name}.log_group_name}",
            pattern: "${aws_cloudwatch_log_metric_filter.#{name}.pattern}"
          },
          computed_properties: {
            pattern_type: filter_attrs.pattern_type,
            extracts_numeric_value: filter_attrs.extracts_numeric_value?,
            has_dimensions: filter_attrs.has_dimensions?,
            has_default_value: filter_attrs.has_default_value?,
            metric_namespace: filter_attrs.metric_namespace,
            metric_name: filter_attrs.metric_name
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)