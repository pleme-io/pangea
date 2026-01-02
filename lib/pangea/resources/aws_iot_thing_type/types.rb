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

require 'pangea/resources/types'

require_relative 'types/properties'
require_relative 'types/recommendations'
require_relative 'types/templates'
require_relative 'types/analysis'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS IoT Thing Type resources
        class IotThingTypeAttributes < Dry::Struct
          include Properties
          include Recommendations
          include Templates
          include Analysis

          # Thing type name (required)
          attribute :thing_type_name, Resources::Types::IotThingTypeName

          # Thing type properties (optional)
          attribute :thing_type_properties, Resources::Types::IotThingTypeProperties.optional

          # Tags (optional)
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            # Validate searchable attributes don't exceed limit
            if attrs.thing_type_properties&.dig(:searchable_attributes)
              searchable = attrs.thing_type_properties[:searchable_attributes]
              if searchable.length > 3
                raise Dry::Struct::Error, 'Thing type cannot have more than 3 searchable attributes'
              end
            end

            attrs
          end
        end
      end
    end
  end
end
