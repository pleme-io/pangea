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
require 'pangea/resources/aws_ram_resource_share/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a Resource Access Manager (RAM) Resource Share.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ram_resource_share(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::RamResourceShareAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ram_resource_share, name) do
          name attrs.name if attrs.name
          allow_external_principals attrs.allow_external_principals if attrs.allow_external_principals
          permission_arns attrs.permission_arns if attrs.permission_arns
          
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
          type: 'aws_ram_resource_share',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_ram_resource_share.#{name}.id}",
            arn: "${aws_ram_resource_share.#{name}.arn}",
            status: "${aws_ram_resource_share.#{name}.status}"
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