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
              raise Dry::Struct::Error, 'Metric query must have either expression or metric'
            end

            if attrs[:expression] && attrs[:metric]
              raise Dry::Struct::Error, 'Metric query cannot have both expression and metric'
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
      end
    end
  end
end
