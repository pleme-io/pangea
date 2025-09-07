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
    # AWS IoT Thing Group Resource
    # 
    # Thing groups allow you to organize your devices into logical groups and manage them collectively.
    # This is essential for fleet management, applying policies to multiple devices, and organizing
    # devices by function, location, or other criteria.
    #
    # @example Basic thing group
    #   aws_iot_thing_group(:sensors, {
    #     thing_group_name: "temperature-sensors",
    #     thing_group_properties: {
    #       description: "Temperature monitoring sensors",
    #       attribute_payload: {
    #         attributes: {
    #           "sensor_type" => "temperature",
    #           "deployment_region" => "us-west-2"
    #         }
    #       }
    #     }
    #   })
    #
    # @example Hierarchical thing group
    #   aws_iot_thing_group(:building_sensors, {
    #     thing_group_name: "building-a-sensors", 
    #     parent_group_name: "campus-sensors",
    #     thing_group_properties: {
    #       description: "Sensors for Building A",
    #       attribute_payload: {
    #         attributes: {
    #           "building_id" => "building-a",
    #           "floor_count" => "5"
    #         }
    #       }
    #     }
    #   })
    #
    # @example Thing group with tags
    #   aws_iot_thing_group(:production_devices, {
    #     thing_group_name: "production-line-1",
    #     thing_group_properties: {
    #       description: "Production line 1 devices"
    #     },
    #     tags: {
    #       "Environment" => "Production",
    #       "CostCenter" => "Manufacturing",
    #       "MaintenanceSchedule" => "Weekly"
    #     }
    #   })
    module AwsIotThingGroup
      include AwsIotThingGroupTypes

      # Creates an AWS IoT thing group for device fleet management
      #
      # @param name [Symbol] Logical name for the thing group resource
      # @param attributes [Hash] Thing group configuration attributes
      # @return [Reference] Resource reference for use in other resources
      def aws_iot_thing_group(name, attributes = {})
        validated_attributes = Attributes[attributes]
        
        resource :aws_iot_thing_group, name do
          thing_group_name validated_attributes.thing_group_name
          parent_group_name validated_attributes.parent_group_name if validated_attributes.parent_group_name

          if validated_attributes.thing_group_properties
            thing_group_properties do
              description validated_attributes.thing_group_properties.description if validated_attributes.thing_group_properties.description
              
              if validated_attributes.thing_group_properties.attribute_payload
                attribute_payload do
                  if validated_attributes.thing_group_properties.attribute_payload.attributes
                    attributes validated_attributes.thing_group_properties.attribute_payload.attributes
                  end
                  if validated_attributes.thing_group_properties.attribute_payload.merge
                    merge validated_attributes.thing_group_properties.attribute_payload.merge
                  end
                end
              end
            end
          end

          tags validated_attributes.tags if validated_attributes.tags
        end

        Reference.new(
          type: :aws_iot_thing_group,
          name: name,
          attributes: Outputs.new(
            arn: "${aws_iot_thing_group.#{name}.arn}",
            id: "${aws_iot_thing_group.#{name}.id}",
            thing_group_name: "${aws_iot_thing_group.#{name}.thing_group_name}",
            version: "${aws_iot_thing_group.#{name}.version}",
            metadata: Outputs::Metadata.new(
              creation_date: "${aws_iot_thing_group.#{name}.metadata[0].creation_date}",
              parent_group_name: "${aws_iot_thing_group.#{name}.metadata[0].parent_group_name}",
              root_to_parent_thing_groups: "${aws_iot_thing_group.#{name}.metadata[0].root_to_parent_thing_groups}"
            )
          )
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)