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
        # Shared tag filter schema for EC2 and on-premises instances
        TagFilterSchema = Resources::Types::Hash.schema(
          type?: Resources::Types::String.enum('KEY_ONLY', 'VALUE_ONLY', 'KEY_AND_VALUE').optional,
          key?: Resources::Types::String.optional,
          value?: Resources::Types::String.optional
        )

        # Tag filter attributes for CodeDeploy deployment groups
        class TagFilterAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # EC2 tag filters (for EC2/Server platform)
          attribute :ec2_tag_filters, Resources::Types::Array.of(TagFilterSchema).default([].freeze)

          # On-premises instance tag filters
          attribute :on_premises_instance_tag_filters, Resources::Types::Array.of(TagFilterSchema).default([].freeze)
        end
      end
    end
  end
end
