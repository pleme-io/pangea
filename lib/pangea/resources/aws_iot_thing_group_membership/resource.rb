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


require_relative 'types'
require 'pangea/resources/base'

module Pangea
  module Resources
    # AWS IoT Thing Group Membership Resource
    # 
    # Manages membership of IoT things in thing groups. This resource allows you to dynamically
    # add or remove devices from groups, which is essential for fleet management, policy application,
    # and device organization strategies.
    #
    # @example Add thing to group
    #   aws_iot_thing_group_membership(:sensor_membership, {
    #     thing_group_name: "temperature-sensors",
    #     thing_name: "sensor-001"
    #   })
    #
    # @example Add thing to group with dynamic group override
    #   aws_iot_thing_group_membership(:critical_device_membership, {
    #     thing_group_name: "critical-devices",
    #     thing_name: "pump-controller-01",
    #     override_dynamic_groups: true
    #   })
    #
    # @example Reference-based membership (using other resources)
    #   aws_iot_thing_group_membership(:fleet_membership, {
    #     thing_group_name: ref(:aws_iot_thing_group, :production_fleet, :thing_group_name),
    #     thing_name: ref(:aws_iot_thing, :device_001, :thing_name)
    #   })
    module AwsIotThingGroupMembership
      include AwsIotThingGroupMembershipTypes

      # Creates an AWS IoT thing group membership
      #
      # @param name [Symbol] Logical name for the membership resource
      # @param attributes [Hash] Membership configuration attributes
      # @return [Reference] Resource reference for use in other resources
      def aws_iot_thing_group_membership(name, attributes = {})
        validated_attributes = Attributes[attributes]
        
        resource :aws_iot_thing_group_membership, name do
          thing_group_name validated_attributes.thing_group_name
          thing_name validated_attributes.thing_name
          override_dynamic_groups validated_attributes.override_dynamic_groups if validated_attributes.override_dynamic_groups
        end

        Reference.new(
          type: :aws_iot_thing_group_membership,
          name: name,
          attributes: Outputs.new(
            id: "${aws_iot_thing_group_membership.#{name}.id}",
            thing_group_name: "${aws_iot_thing_group_membership.#{name}.thing_group_name}",
            thing_name: "${aws_iot_thing_group_membership.#{name}.thing_name}"
          )
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)