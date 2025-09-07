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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_iot_thing_type/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS IoT Thing Type with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] IoT Thing Type attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_iot_thing_type(name, attributes = {})
        # Validate attributes using dry-struct
        thing_type_attrs = Types::IotThingTypeAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_iot_thing_type, name) do
          # Required attributes
          thing_type_name thing_type_attrs.thing_type_name
          
          # Optional thing type properties
          if thing_type_attrs.thing_type_properties
            thing_type_properties do
              props = thing_type_attrs.thing_type_properties
              
              # Description
              description props[:description] if props[:description]
              
              # Searchable attributes
              if props[:searchable_attributes]&.any?
                searchable_attributes props[:searchable_attributes]
              end
            end
          end
          
          # Apply tags if present
          if thing_type_attrs.tags.any?
            tags do
              thing_type_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_iot_thing_type',
          name: name,
          resource_attributes: thing_type_attrs.to_h,
          outputs: {
            thing_type_name: "${aws_iot_thing_type.#{name}.thing_type_name}",
            thing_type_arn: "${aws_iot_thing_type.#{name}.arn}",
            thing_type_id: "${aws_iot_thing_type.#{name}.thing_type_id}",
            description: "${aws_iot_thing_type.#{name}.thing_type_properties[0].description}",
            searchable_attributes: "${aws_iot_thing_type.#{name}.thing_type_properties[0].searchable_attributes}",
            creation_date: "${aws_iot_thing_type.#{name}.creation_date}",
            deprecated: "${aws_iot_thing_type.#{name}.deprecated}",
            deprecation_date: "${aws_iot_thing_type.#{name}.deprecation_date}",
            tags_all: "${aws_iot_thing_type.#{name}.tags_all}"
          },
          computed_properties: {
            has_description: thing_type_attrs.has_description?,
            description_text: thing_type_attrs.description_text,
            has_searchable_attributes: thing_type_attrs.has_searchable_attributes?,
            searchable_attributes_list: thing_type_attrs.searchable_attributes_list,
            searchable_attribute_count: thing_type_attrs.searchable_attribute_count,
            fleet_indexing_optimized: thing_type_attrs.fleet_indexing_optimized?,
            recommended_thing_attributes: thing_type_attrs.recommended_thing_attributes,
            security_recommendations: thing_type_attrs.security_recommendations,
            example_thing_configuration: thing_type_attrs.example_thing_configuration,
            required_permissions: thing_type_attrs.required_permissions,
            cost_impact_analysis: thing_type_attrs.cost_impact_analysis
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)