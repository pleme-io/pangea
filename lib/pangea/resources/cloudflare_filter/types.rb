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
    module Cloudflare
      module Types
        # Cloudflare Filter resource attributes with validation
        class FilterAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId
          attribute :expression, ::Pangea::Resources::Types::CloudflareFilterExpression
          attribute :description, ::Pangea::Resources::Types::String.optional.default(nil)
          attribute :ref, ::Pangea::Resources::Types::String.optional.default(nil)
          attribute :paused, ::Pangea::Resources::Types::Bool.default(false)

          # Computed properties
          def is_active?
            !paused
          end

          def is_paused?
            paused
          end

          def has_description?
            !description.nil?
          end

          def expression_length
            expression.length
          end
        end
      end
    end
  end
end
