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
        # Target tracking configuration
        class TargetTrackingConfiguration < Dry::Struct
          transform_keys(&:to_sym)

          attribute :target_value, Resources::Types::Float
          attribute :disable_scale_in, Resources::Types::Bool.default(false)
          attribute :scale_in_cooldown, Resources::Types::Integer.optional.default(nil)
          attribute :scale_out_cooldown, Resources::Types::Integer.optional.default(nil)

          # Predefined metric specification
          attribute :predefined_metric_specification, Resources::Types::Hash.schema(
            predefined_metric_type: Resources::Types::String.enum(
              'ASGAverageCPUUtilization',
              'ASGAverageNetworkIn',
              'ASGAverageNetworkOut',
              'ALBRequestCountPerTarget'
            ),
            resource_label: Resources::Types::String.optional
          ).optional.default(nil)

          # Custom metric specification
          attribute :customized_metric_specification, Resources::Types::Hash.schema(
            metric_name: Resources::Types::String,
            namespace: Resources::Types::String,
            statistic: Resources::Types::String.enum('Average', 'Minimum', 'Maximum', 'SampleCount', 'Sum'),
            unit: Resources::Types::String.optional,
            dimensions: Resources::Types::Hash.optional
          ).optional.default(nil)

          # Validate exactly one metric specification
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            metrics = [
              attrs[:predefined_metric_specification],
              attrs[:customized_metric_specification]
            ].compact

            if metrics.empty?
              raise Dry::Struct::Error, 'Target tracking must specify either predefined_metric_specification or customized_metric_specification'
            end

            if metrics.size > 1
              raise Dry::Struct::Error, 'Target tracking can only specify one metric specification'
            end

            super(attrs)
          end

          def to_h
            hash = {
              target_value: target_value,
              disable_scale_in: disable_scale_in
            }

            hash[:scale_in_cooldown] = scale_in_cooldown if scale_in_cooldown
            hash[:scale_out_cooldown] = scale_out_cooldown if scale_out_cooldown
            hash[:predefined_metric_specification] = predefined_metric_specification if predefined_metric_specification
            hash[:customized_metric_specification] = customized_metric_specification if customized_metric_specification

            hash.compact
          end
        end
      end
    end
  end
end
