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
require 'pangea/resources/aws_ram_managed_permission/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Retrieves information about a Resource Access Manager (RAM) managed permission.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ram_managed_permission(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::RamManagedPermissionAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ram_managed_permission, name) do
          name attrs.name if attrs.name
          resource_type attrs.resource_type if attrs.resource_type
          
          # Apply tags if present
          if attrs.tags.any?
            tags do
              attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ram_managed_permission',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_ram_managed_permission.#{name}.id}",
            arn: "${aws_ram_managed_permission.#{name}.arn}",
            version: "${aws_ram_managed_permission.#{name}.version}",
            default_version: "${aws_ram_managed_permission.#{name}.default_version}",
            type: "${aws_ram_managed_permission.#{name}.type}",
            status: "${aws_ram_managed_permission.#{name}.status}",
            creation_time: "${aws_ram_managed_permission.#{name}.creation_time}",
            last_updated_time: "${aws_ram_managed_permission.#{name}.last_updated_time}"
          },
          computed_properties: {
            # Computed properties from type definitions
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)