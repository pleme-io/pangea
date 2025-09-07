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
    # AWS IoT Thing Group Membership Types
    # 
    # Thing group membership allows you to add or remove individual IoT things from thing groups.
    # This resource manages the many-to-many relationship between things and thing groups, enabling
    # dynamic fleet management and device organization.
    module AwsIotThingGroupMembershipTypes
      # Main attributes for IoT thing group membership resource
      class Attributes < Dry::Struct
        schema schema.strict

        # Name of the thing group to manage membership for
        attribute :thing_group_name, Resources::Types::String

        # Name of the thing to add to the group
        attribute :thing_name, Resources::Types::String

        # Whether to override dynamic thing groups (optional)
        attribute :override_dynamic_groups, Resources::Types::Bool.optional
      end

      # Output attributes from thing group membership resource  
      class Outputs < Dry::Struct
        schema schema.strict

        # The thing group membership ID (combination of thing and group names)
        attribute :id, Resources::Types::String

        # The name of the thing group
        attribute :thing_group_name, Resources::Types::String

        # The name of the thing
        attribute :thing_name, Resources::Types::String
      end
    end
  end
end