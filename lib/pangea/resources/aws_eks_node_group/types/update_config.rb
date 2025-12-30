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
        # Update configuration for managed node group
        class UpdateConfig < Dry::Struct
          transform_keys(&:to_sym)

          attribute :max_unavailable, Pangea::Resources::Types::Integer.optional.default(nil).constrained(gteq: 1)
          attribute :max_unavailable_percentage, Pangea::Resources::Types::Integer.optional.default(nil).constrained(
            gteq: 1, lteq: 100
          )

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate that only one type of max_unavailable is specified
            if attrs[:max_unavailable] && attrs[:max_unavailable_percentage]
              raise Dry::Struct::Error, 'Cannot specify both max_unavailable and max_unavailable_percentage'
            end

            super(attrs)
          end

          def to_h
            hash = {}
            hash[:max_unavailable] = max_unavailable if max_unavailable
            hash[:max_unavailable_percentage] = max_unavailable_percentage if max_unavailable_percentage
            hash
          end
        end
      end
    end
  end
end
