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
        # Taint configuration for node group
        class Taint < Dry::Struct
          transform_keys(&:to_sym)

          VALID_EFFECTS = %w[NO_SCHEDULE NO_EXECUTE PREFER_NO_SCHEDULE].freeze

          attribute :key, Pangea::Resources::Types::String
          attribute :value, Pangea::Resources::Types::String.optional.default(nil)
          attribute :effect, Pangea::Resources::Types::String.constrained(included_in: VALID_EFFECTS)

          def to_h
            hash = { key: key, effect: effect }
            hash[:value] = value if value
            hash
          end
        end
      end
    end
  end
end
