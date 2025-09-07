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
    # AWS IoT Thing Group Types
    # 
    # Thing groups enable you to manage fleets of things by grouping them and applying the same configuration,
    # policies, or job to all things in a group. You can use thing groups to apply the same configuration to
    # multiple things at once and to simplify device fleet management.
    module AwsIotThingGroupTypes
      # Thing group properties for device management
      class ThingGroupProperties < Dry::Struct
        schema schema.strict

        # Brief description of thing group
        attribute :description, Resources::Types::String.optional

        # Attribute payload for additional metadata
        class AttributePayload < Dry::Struct
          schema schema.strict
          
          # Map of attributes and their values
          attribute :attributes, Resources::Types::Hash.map(Types::String, Types::String).optional
          
          # Whether payload should merge or replace existing attributes
          attribute :merge, Resources::Types::Bool.optional
        end

        attribute? :attribute_payload, AttributePayload.optional
      end

      # Main attributes for IoT thing group resource
      class Attributes < Dry::Struct
        schema schema.strict

        # Name of the thing group (must be unique within account)
        attribute :thing_group_name, Resources::Types::String

        # Parent thing group name for hierarchical organization
        attribute :parent_group_name, Resources::Types::String.optional

        # Properties for thing group configuration  
        attribute? :thing_group_properties, ThingGroupProperties.optional

        # Resource tags for organization and billing
        attribute :tags, Resources::Types::Hash.map(Types::String, Types::String).optional
      end

      # Output attributes from thing group resource
      class Outputs < Dry::Struct
        schema schema.strict

        # The thing group ARN
        attribute :arn, Resources::Types::String

        # The thing group ID
        attribute :id, Resources::Types::String

        # The thing group name
        attribute :thing_group_name, Resources::Types::String

        # The thing group version for optimistic locking
        attribute :version, Resources::Types::Integer

        # Metadata about thing group creation
        class Metadata < Dry::Struct
          schema schema.strict

          # Creation date of thing group
          attribute :creation_date, Resources::Types::String

          # Parent group ARN if this is a child group
          attribute :parent_group_name, Resources::Types::String.optional

          # Root to this group path for navigation
          attribute :root_to_parent_thing_groups, Resources::Types::Array.of(Types::String).optional
        end

        attribute :metadata, Metadata
      end
    end
  end
end