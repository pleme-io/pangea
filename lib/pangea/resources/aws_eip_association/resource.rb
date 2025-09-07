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
require 'pangea/resources/aws_eip_association/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides an AWS EIP Association as a top level resource, to associate and disassociate Elastic IPs from AWS Instances and Network Interfaces.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_eip_association(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::EipAssociationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_eip_association, name) do
          allocation_id attrs.allocation_id if attrs.allocation_id
          allow_reassociation attrs.allow_reassociation if attrs.allow_reassociation
          instance_id attrs.instance_id if attrs.instance_id
          network_interface_id attrs.network_interface_id if attrs.network_interface_id
          private_ip_address attrs.private_ip_address if attrs.private_ip_address
          public_ip attrs.public_ip if attrs.public_ip
          
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
          type: 'aws_eip_association',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_eip_association.#{name}.id}",
            allocation_id: "${aws_eip_association.#{name}.allocation_id}",
            instance_id: "${aws_eip_association.#{name}.instance_id}",
            network_interface_id: "${aws_eip_association.#{name}.network_interface_id}",
            private_ip_address: "${aws_eip_association.#{name}.private_ip_address}",
            public_ip: "${aws_eip_association.#{name}.public_ip}"
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