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
        class CloudWatchMetricAlarmAttributes
          # Instance methods for CloudWatch metric alarm attributes
          module InstanceMethods
            # Computed properties
            def is_metric_math_alarm?
              metric_query.any?
            end

            def is_traditional_alarm?
              !metric_name.nil? && !namespace.nil?
            end

            def uses_anomaly_detector?
              comparison_operator.include?('LowerOrGreaterThan') ||
                comparison_operator.include?('LowerThreshold') ||
                comparison_operator.include?('UpperThreshold')
            end

            def to_h
              hash = build_common_attributes
              add_optional_attributes(hash)
              add_action_attributes(hash)
              add_traditional_alarm_attributes(hash) if is_traditional_alarm?
              add_metric_math_attributes(hash) if is_metric_math_alarm?
              hash.compact
            end

            private

            def build_common_attributes
              {
                comparison_operator: comparison_operator,
                evaluation_periods: evaluation_periods,
                actions_enabled: actions_enabled,
                treat_missing_data: treat_missing_data,
                tags: tags
              }
            end

            def add_optional_attributes(hash)
              hash[:alarm_name] = alarm_name if alarm_name
              hash[:alarm_description] = alarm_description if alarm_description
              hash[:datapoints_to_alarm] = datapoints_to_alarm if datapoints_to_alarm
              hash[:evaluate_low_sample_count_percentile] = evaluate_low_sample_count_percentile if evaluate_low_sample_count_percentile
            end

            def add_action_attributes(hash)
              hash[:alarm_actions] = alarm_actions if alarm_actions.any?
              hash[:ok_actions] = ok_actions if ok_actions.any?
              hash[:insufficient_data_actions] = insufficient_data_actions if insufficient_data_actions.any?
            end

            def add_traditional_alarm_attributes(hash)
              hash[:metric_name] = metric_name
              hash[:namespace] = namespace
              hash[:period] = period
              hash[:statistic] = statistic if statistic
              hash[:extended_statistic] = extended_statistic if extended_statistic
              hash[:unit] = unit if unit
              hash[:dimensions] = dimensions if dimensions.any?
              hash[:threshold] = threshold
            end

            def add_metric_math_attributes(hash)
              hash[:metric_query] = metric_query.map(&:to_h)
              hash[:threshold] = threshold if threshold
              hash[:threshold_metric_id] = threshold_metric_id if threshold_metric_id
            end
          end
        end
      end
    end
  end
end
