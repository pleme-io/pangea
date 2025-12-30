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
        # Launch template specification for ASG
        class LaunchTemplateSpecification < Dry::Struct
          transform_keys(&:to_sym)

          attribute :id, Resources::Types::String.optional.default(nil)
          attribute :name, Resources::Types::String.optional.default(nil)
          attribute :version, Resources::Types::String.default('$Latest')

          # Validate that either id or name is specified
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            unless attrs[:id] || attrs[:name]
              raise Dry::Struct::Error, "Launch template must specify either 'id' or 'name'"
            end

            if attrs[:id] && attrs[:name]
              raise Dry::Struct::Error, "Launch template cannot specify both 'id' and 'name'"
            end

            super(attrs)
          end

          def to_h
            {
              id: id,
              name: name,
              version: version
            }.compact
          end
        end
      end
    end
  end
end
