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
        # Scaling configuration for node group
        class ScalingConfig < Dry::Struct
          transform_keys(&:to_sym)

          attribute :desired_size, Pangea::Resources::Types::Integer.constrained(gteq: 0).default(2)
          attribute :max_size, Pangea::Resources::Types::Integer.constrained(gteq: 1).default(4)
          attribute :min_size, Pangea::Resources::Types::Integer.constrained(gteq: 0).default(1)

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate size relationships
            min = attrs[:min_size] || 1
            max = attrs[:max_size] || 4
            desired = attrs[:desired_size] || 2

            if min > max
              raise Dry::Struct::Error, "min_size (#{min}) cannot be greater than max_size (#{max})"
            end

            if desired < min || desired > max
              raise Dry::Struct::Error, "desired_size (#{desired}) must be between min_size (#{min}) and max_size (#{max})"
            end

            super(attrs)
          end

          def to_h
            {
              desired_size: desired_size,
              max_size: max_size,
              min_size: min_size
            }
          end
        end
      end
    end
  end
end
