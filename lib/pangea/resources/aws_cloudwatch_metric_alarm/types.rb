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

require_relative 'types/metric_query'
require_relative 'types/validation'
require_relative 'types/instance_methods'

module Pangea
  module Resources
    module AWS
      module Types
        # CloudWatch Metric Alarm resource attributes with validation
        class CloudWatchMetricAlarmAttributes < Dry::Struct
          include InstanceMethods

          transform_keys(&:to_sym)

          # Required for traditional alarms
          attribute :alarm_name?, Pangea::Resources::Types::String.optional
          attribute :alarm_description?, Pangea::Resources::Types::String.optional
          attribute :comparison_operator, Pangea::Resources::Types::String.constrained(
            included_in: %w[
              GreaterThanOrEqualToThreshold
              GreaterThanThreshold
              LessThanThreshold
              LessThanOrEqualToThreshold
              LessThanLowerOrGreaterThanUpperThreshold
              LessThanLowerThreshold
              GreaterThanUpperThreshold
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
            included_in: %w[SampleCount Average Sum Minimum Maximum]
          )
          attribute :extended_statistic?, Pangea::Resources::Types::String.optional
          attribute :unit?, Pangea::Resources::Types::String.optional
          attribute :dimensions?, Pangea::Resources::Types::Hash.optional.default(proc { {} }.freeze)

          # Metric math alarm attributes
          attribute :metric_query?, Pangea::Resources::Types::Array.of(MetricQuery).optional.default(proc { [] }.freeze)

          # Alarm actions
          attribute :actions_enabled?, Pangea::Resources::Types::Bool.optional.default(true)
          attribute :alarm_actions?, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::String
          ).optional.default(proc { [] }.freeze)
          attribute :ok_actions?, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::String
          ).optional.default(proc { [] }.freeze)
          attribute :insufficient_data_actions?, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::String
          ).optional.default(proc { [] }.freeze)

          # Additional options
          attribute :datapoints_to_alarm?, Pangea::Resources::Types::Integer.optional
          attribute :treat_missing_data?, Pangea::Resources::Types::String.optional.default('missing').constrained(
            included_in: %w[breaching notBreaching ignore missing]
          )
          attribute :evaluate_low_sample_count_percentile?, Pangea::Resources::Types::String.optional.constrained(
            included_in: %w[evaluate ignore]
          )

          # Tags
          attribute :tags?, Pangea::Resources::Types::AwsTags.optional.default(proc { {} }.freeze)

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            Validation.validate_all(attrs)
            super(attrs)
          end
        end
      end
    end
  end
end
