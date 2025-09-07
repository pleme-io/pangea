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
require 'pangea/resources/aws_iot_thing/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS IoT Thing with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] IoT Thing attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_iot_thing(name, attributes = {})
        # Validate attributes using dry-struct
        thing_attrs = Types::IotThingAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_iot_thing, name) do
          # Required attributes
          thing_name thing_attrs.thing_name
          
          # Optional thing type
          thing_type_name thing_attrs.thing_type_name if thing_attrs.thing_type_name
          
          # Attribute payload configuration
          attribute_payload do
            # Set attributes if provided
            if thing_attrs.attribute_payload[:attributes]&.any?
              attributes do
                thing_attrs.attribute_payload[:attributes].each do |key, value|
                  public_send(key, value)
                end
              end
            end
            
            # Set merge behavior
            merge thing_attrs.attribute_payload[:merge] unless thing_attrs.attribute_payload[:merge].nil?
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_iot_thing',
          name: name,
          resource_attributes: thing_attrs.to_h,
          outputs: {
            thing_name: "${aws_iot_thing.#{name}.thing_name}",
            thing_arn: "${aws_iot_thing.#{name}.arn}",
            thing_id: "${aws_iot_thing.#{name}.thing_id}",
            thing_type_name: "${aws_iot_thing.#{name}.thing_type_name}",
            attributes: "${aws_iot_thing.#{name}.attributes}",
            default_client_id: "${aws_iot_thing.#{name}.default_client_id}",
            version: "${aws_iot_thing.#{name}.version}"
          },
          computed_properties: {
            attribute_count: thing_attrs.attribute_count,
            has_type: thing_attrs.has_type?,
            fleet_indexing_ready: thing_attrs.fleet_indexing_ready?,
            estimated_storage_bytes: thing_attrs.estimated_storage_bytes,
            security_recommendations: thing_attrs.security_recommendations,
            required_permissions: thing_attrs.required_permissions
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)