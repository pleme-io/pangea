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
        # Predictive scaling configuration
        class PredictiveScalingConfiguration < Dry::Struct
          transform_keys(&:to_sym)

          attribute :mode, Resources::Types::String.default('ForecastOnly').enum('ForecastOnly', 'ForecastAndScale')
          attribute :scheduling_buffer_time, Resources::Types::Integer.optional.default(nil)
          attribute :max_capacity_breach_behavior, Resources::Types::String.default('HonorMaxCapacity').enum('HonorMaxCapacity', 'IncreaseMaxCapacity')
          attribute :max_capacity_buffer, Resources::Types::Integer.optional.default(nil)

          # Metric specifications would go here (simplified for this example)
          attribute :metric_specifications, Resources::Types::Array.default([].freeze)

          def to_h
            attributes.reject { |_, v| v.nil? || (v.respond_to?(:empty?) && v.empty?) }
          end
        end
      end
    end
  end
end
