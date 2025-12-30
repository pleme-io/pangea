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
        # Tag specification for Auto Scaling Groups
        class TagSpecification < Dry::Struct
          transform_keys(&:to_sym)

          attribute :key, Resources::Types::String
          attribute :value, Resources::Types::String
          attribute :propagate_at_launch, Resources::Types::Bool

          def to_h
            {
              key: key,
              value: value,
              propagate_at_launch: propagate_at_launch
            }
          end
        end
      end
    end
  end
end
