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
        # Metric query for metric math alarms
        class MetricQuery < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :id, Pangea::Resources::Types::String
          attribute :expression?, Pangea::Resources::Types::String.optional
          attribute :label?, Pangea::Resources::Types::String.optional
          attribute :return_data?, Pangea::Resources::Types::Bool.optional.default(false)
          
          # Metric specification (if not using expression)
          attribute :metric?, Pangea::Resources::Types::Hash.schema(
            metric_name: Pangea::Resources::Types::String,
            namespace: Pangea::Resources::Types::String,
            period: Pangea::Resources::Types::Integer,
            stat: Pangea::Resources::Types::String,
            unit?: Pangea::Resources::Types::String.optional,
            dimensions?: Pangea::Resources::Types::Hash.optional
          ).optional
          
          # Validate either expression or metric is provided
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            unless attrs[:expression] || attrs[:metric]
              raise Dry::Struct::Error, "Metric query must have either expression or metric"
            end
            
            if attrs[:expression] && attrs[:metric]
              raise Dry::Struct::Error, "Metric query cannot have both expression and metric"
            end
            
            super(attrs)
          end
          
          def to_h
            hash = {
              id: id,
              return_data: return_data
            }
            
            hash[:expression] = expression if expression
            hash[:label] = label if label
            hash[:metric] = metric if metric
            
            hash.compact
          end
        end
        
        # CloudWatch Metric Alarm resource attributes with validation
        class CloudWatchMetricAlarmAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required for traditional alarms
          attribute :alarm_name?, Pangea::Resources::Types::String.optional
          attribute :alarm_description?, Pangea::Resources::Types::String.optional
          attribute :comparison_operator, Pangea::Resources::Types::String.constrained(
            included_in: [
              'GreaterThanOrEqualToThreshold',
              'GreaterThanThreshold', 
              'LessThanThreshold',
              'LessThanOrEqualToThreshold',
              'LessThanLowerOrGreaterThanUpperThreshold',
              'LessThanLowerThreshold',
              'GreaterThanUpperThreshold'
            ]
          )
          attribute :evaluation_periods, Pangea::Resources::Types::Integer.constrained(gteq: 1)
          attribute :threshold?, Pangea::Resources::Types::Float.optional
          attribute :threshold_metric_id?, Pangea::Resources::Types::String.optional
          
          # Traditional metric alarm attributes
          attribute :metric_name?, Pangea::Resources::Types::String.optional
          attribute :namespace?, Pangea::Resources::Types::String.optional
          attribute :period?, Pangea::Resources::Types::Integer.optional
          attribute :statistic?, Pangea::Resources::Types::String.optional.constrained(
            included_in: ['SampleCount', 'Average', 'Sum', 'Minimum', 'Maximum']
          )
          attribute :extended_statistic?, Pangea::Resources::Types::String.optional
          attribute :unit?, Pangea::Resources::Types::String.optional
          attribute :dimensions?, Pangea::Resources::Types::Hash.optional.default(proc { {} }.freeze)
          
          # Metric math alarm attributes
          attribute :metric_query?, Pangea::Resources::Types::Array.of(MetricQuery).optional.default(proc { [] }.freeze)
          
          # Alarm actions
          attribute :actions_enabled?, Pangea::Resources::Types::Bool.optional.default(true)
          attribute :alarm_actions?, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).optional.default(proc { [] }.freeze)
          attribute :ok_actions?, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).optional.default(proc { [] }.freeze)
          attribute :insufficient_data_actions?, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).optional.default(proc { [] }.freeze)
          
          # Additional options
          attribute :datapoints_to_alarm?, Pangea::Resources::Types::Integer.optional
          attribute :treat_missing_data?, Pangea::Resources::Types::String.optional.default('missing').constrained(
            included_in: ['breaching', 'notBreaching', 'ignore', 'missing']
          )
          attribute :evaluate_low_sample_count_percentile?, Pangea::Resources::Types::String.optional.constrained(
            included_in: ['evaluate', 'ignore']
          )
          
          # Tags
          attribute :tags?, Pangea::Resources::Types::AwsTags.optional.default(proc { {} }.freeze)
          
          # Validate alarm type consistency
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Check if it's a metric math alarm or traditional alarm
            is_metric_math = attrs[:metric_query] && !attrs[:metric_query].empty?
            is_traditional = attrs[:metric_name] && attrs[:namespace]
            
            if is_metric_math && is_traditional
              raise Dry::Struct::Error, "Cannot specify both metric_query and metric_name/namespace"
            end
            
            if !is_metric_math && !is_traditional
              raise Dry::Struct::Error, "Must specify either metric_query or metric_name/namespace"
            end
            
            # Traditional alarm validations
            if is_traditional
              required = [:period, :statistic]
              required.each do |attr|
                unless attrs[attr]
                  raise Dry::Struct::Error, "Traditional alarm requires #{attr}"
                end
              end
              
              unless attrs[:threshold]
                raise Dry::Struct::Error, "Traditional alarm requires threshold"
              end
            end
            
            # Metric math alarm validations
            if is_metric_math
              unless attrs[:threshold] || attrs[:threshold_metric_id]
                raise Dry::Struct::Error, "Metric math alarm requires either threshold or threshold_metric_id"
              end
              
              if attrs[:threshold] && attrs[:threshold_metric_id]
                raise Dry::Struct::Error, "Cannot specify both threshold and threshold_metric_id"
              end
            end
            
            # Validate statistic/extended_statistic exclusivity
            if attrs[:statistic] && attrs[:extended_statistic]
              raise Dry::Struct::Error, "Cannot specify both statistic and extended_statistic"
            end
            
            # Validate datapoints_to_alarm
            if attrs[:datapoints_to_alarm] && attrs[:evaluation_periods]
              if attrs[:datapoints_to_alarm] > attrs[:evaluation_periods]
                raise Dry::Struct::Error, "datapoints_to_alarm cannot be greater than evaluation_periods"
              end
            end
            
            super(attrs)
          end
          
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
            hash = {
              comparison_operator: comparison_operator,
              evaluation_periods: evaluation_periods,
              actions_enabled: actions_enabled,
              treat_missing_data: treat_missing_data,
              tags: tags
            }
            
            # Optional common attributes
            hash[:alarm_name] = alarm_name if alarm_name
            hash[:alarm_description] = alarm_description if alarm_description
            hash[:datapoints_to_alarm] = datapoints_to_alarm if datapoints_to_alarm
            hash[:evaluate_low_sample_count_percentile] = evaluate_low_sample_count_percentile if evaluate_low_sample_count_percentile
            
            # Actions
            hash[:alarm_actions] = alarm_actions if alarm_actions.any?
            hash[:ok_actions] = ok_actions if ok_actions.any?
            hash[:insufficient_data_actions] = insufficient_data_actions if insufficient_data_actions.any?
            
            # Traditional alarm attributes
            if is_traditional_alarm?
              hash[:metric_name] = metric_name
              hash[:namespace] = namespace
              hash[:period] = period
              hash[:statistic] = statistic if statistic
              hash[:extended_statistic] = extended_statistic if extended_statistic
              hash[:unit] = unit if unit
              hash[:dimensions] = dimensions if dimensions.any?
              hash[:threshold] = threshold
            end
            
            # Metric math alarm attributes
            if is_metric_math_alarm?
              hash[:metric_query] = metric_query.map(&:to_h)
              hash[:threshold] = threshold if threshold
              hash[:threshold_metric_id] = threshold_metric_id if threshold_metric_id
            end
            
            hash.compact
          end
        end
      end
    end
  end
end