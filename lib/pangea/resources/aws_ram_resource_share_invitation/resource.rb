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
require 'pangea/resources/aws_ram_resource_share_invitation/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Manages a Resource Access Manager (RAM) resource share invitation.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ram_resource_share_invitation(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::RamResourceShareInvitationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ram_resource_share_invitation, name) do
          resource_share_arn attrs.resource_share_arn if attrs.resource_share_arn
          receiver_account_id attrs.receiver_account_id if attrs.receiver_account_id
          
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
          type: 'aws_ram_resource_share_invitation',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_ram_resource_share_invitation.#{name}.id}",
            invitation_arn: "${aws_ram_resource_share_invitation.#{name}.invitation_arn}",
            sender_account_id: "${aws_ram_resource_share_invitation.#{name}.sender_account_id}",
            resource_share_name: "${aws_ram_resource_share_invitation.#{name}.resource_share_name}",
            status: "${aws_ram_resource_share_invitation.#{name}.status}",
            invitation_timestamp: "${aws_ram_resource_share_invitation.#{name}.invitation_timestamp}"
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