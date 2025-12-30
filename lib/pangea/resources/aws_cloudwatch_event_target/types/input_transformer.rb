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
        # Input transformer configuration for CloudWatch Event targets
        class InputTransformer < Dry::Struct
          transform_keys(&:to_sym)

          attribute :input_paths_map, Resources::Types::Hash.default({}.freeze)
          attribute :input_template, Resources::Types::String

          def to_h
            {
              input_paths_map: input_paths_map,
              input_template: input_template
            }.compact
          end
        end
      end
    end
  end
end
