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
require_relative 'types/tag_specification'
require_relative 'types/tag_validator'
require_relative 'types/tag_queries'

module Pangea
  module Resources
    module AWS
      module Types
        # Auto Scaling Group tag attributes with validation
        class AutoScalingTagAttributes < Dry::Struct
          transform_keys(&:to_sym)
          include TagQueries

          # Required attributes
          attribute :autoscaling_group_name, Resources::Types::String
          attribute :tags, Resources::Types::Array.of(TagSpecification).constrained(min_size: 1)

          # Validate configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            if attrs[:autoscaling_group_name]
              TagValidator.validate_group_name(attrs[:autoscaling_group_name])
            end

            if attrs[:tags]
              TagValidator.validate_tags(attrs[:tags])
            end

            super(attrs)
          end

          def to_h
            {
              autoscaling_group_name: autoscaling_group_name,
              tags: tags.map(&:to_h)
            }
          end
        end
      end
    end
  end
end
