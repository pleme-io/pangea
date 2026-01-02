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
        # Dashboard widget configuration
        class DashboardWidget < Dry::Struct
          transform_keys(&:to_sym)

          attribute :type, Resources::Types::String.enum(
            'metric', 'text', 'log', 'number', 'explorer'
          )
          attribute :x, Resources::Types::Integer.constrained(gteq: 0, lt: 24)
          attribute :y, Resources::Types::Integer.constrained(gteq: 0)
          attribute :width, Resources::Types::Integer.constrained(gteq: 1, lteq: 24)
          attribute :height, Resources::Types::Integer.constrained(gteq: 1)
          attribute :properties, DashboardWidgetProperties

          # Validate widget configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate x + width doesn't exceed 24 (grid width)
            if attrs[:x] && attrs[:width] && (attrs[:x] + attrs[:width] > 24)
              raise Dry::Struct::Error, "Widget x position (#{attrs[:x]}) + width (#{attrs[:width]}) cannot exceed 24"
            end

            # Validate type-specific properties
            validate_type_specific_properties(attrs) if attrs[:type] && attrs[:properties]

            super(attrs)
          end

          def self.validate_type_specific_properties(attrs)
            case attrs[:type]
            when 'metric', 'number', 'explorer'
              unless attrs[:properties][:metrics] || attrs[:properties][:query]
                raise Dry::Struct::Error, 'Metric widgets require either metrics or query property'
              end
            when 'text'
              unless attrs[:properties][:markdown]
                raise Dry::Struct::Error, 'Text widgets require markdown property'
              end
            when 'log'
              unless attrs[:properties][:query] && attrs[:properties][:source]
                raise Dry::Struct::Error, 'Log widgets require both query and source properties'
              end
            end
          end

          def to_h
            {
              type: type,
              x: x,
              y: y,
              width: width,
              height: height,
              properties: properties.to_h
            }
          end
        end
      end
    end
  end
end
