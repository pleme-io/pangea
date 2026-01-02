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
          # Validation methods for CloudWatch metric alarm attributes
          module Validation
            def self.validate_alarm_type(attrs)
              is_metric_math = attrs[:metric_query] && !attrs[:metric_query].empty?
              is_traditional = attrs[:metric_name] && attrs[:namespace]

              if is_metric_math && is_traditional
                raise Dry::Struct::Error, 'Cannot specify both metric_query and metric_name/namespace'
              end

              unless is_metric_math || is_traditional
                raise Dry::Struct::Error, 'Must specify either metric_query or metric_name/namespace'
              end

              { is_metric_math: is_metric_math, is_traditional: is_traditional }
            end

            def self.validate_traditional_alarm(attrs)
              required = %i[period statistic]
              required.each do |attr|
                raise Dry::Struct::Error, "Traditional alarm requires #{attr}" unless attrs[attr]
              end

              raise Dry::Struct::Error, 'Traditional alarm requires threshold' unless attrs[:threshold]
            end

            def self.validate_metric_math_alarm(attrs)
              unless attrs[:threshold] || attrs[:threshold_metric_id]
                raise Dry::Struct::Error, 'Metric math alarm requires either threshold or threshold_metric_id'
              end

              return unless attrs[:threshold] && attrs[:threshold_metric_id]

              raise Dry::Struct::Error, 'Cannot specify both threshold and threshold_metric_id'
            end

            def self.validate_statistic_exclusivity(attrs)
              return unless attrs[:statistic] && attrs[:extended_statistic]

              raise Dry::Struct::Error, 'Cannot specify both statistic and extended_statistic'
            end

            def self.validate_datapoints_to_alarm(attrs)
              return unless attrs[:datapoints_to_alarm] && attrs[:evaluation_periods]
              return unless attrs[:datapoints_to_alarm] > attrs[:evaluation_periods]

              raise Dry::Struct::Error, 'datapoints_to_alarm cannot be greater than evaluation_periods'
            end

            def self.validate_all(attrs)
              alarm_type = validate_alarm_type(attrs)
              validate_traditional_alarm(attrs) if alarm_type[:is_traditional]
              validate_metric_math_alarm(attrs) if alarm_type[:is_metric_math]
              validate_statistic_exclusivity(attrs)
              validate_datapoints_to_alarm(attrs)
            end
          end
        end
      end
    end
  end
end
