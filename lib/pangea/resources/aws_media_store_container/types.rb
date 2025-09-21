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
      # Type-safe attributes for AWS MediaStore Container resources
      class MediaStoreContainerAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Container name (required)
        attribute :name, Resources::Types::String

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate container name format
          unless attrs.name.match?(/^[a-zA-Z0-9_.-]{1,255}$/)
            raise Dry::Struct::Error, "Container name must be 1-255 characters with letters, numbers, dots, hyphens, underscores"
          end

          attrs
        end

        # Helper methods
        def name_valid?
          name.match?(/^[a-zA-Z0-9_.-]{1,255}$/)
        end
      end
    end
      end
    end
  end
end