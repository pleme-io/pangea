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
require 'pangea/resources/aws_managedblockchain_member/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Managed Blockchain Member with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Managed blockchain member attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_managedblockchain_member(name, attributes = {})
        # Validate attributes using dry-struct
        member_attrs = Types::ManagedBlockchainMemberAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_managedblockchain_member, name) do
          # Set network ID
          network_id member_attrs.network_id
          
          # Set invitation ID if joining existing network
          invitation_id member_attrs.invitation_id if member_attrs.invitation_id
          
          # Set member configuration
          member_configuration do
            # Basic member info
            name member_attrs.member_configuration[:name]
            description member_attrs.member_configuration[:description] if member_attrs.member_configuration[:description]
            
            # Framework configuration
            framework_configuration do
              if member_attrs.member_configuration[:framework_configuration][:member_fabric_configuration]
                member_fabric_configuration do
                  admin_username member_attrs.member_configuration[:framework_configuration][:member_fabric_configuration][:admin_username]
                  admin_password member_attrs.member_configuration[:framework_configuration][:member_fabric_configuration][:admin_password]
                end
              end
            end
            
            # Log publishing configuration
            if member_attrs.member_configuration[:log_publishing_configuration]
              log_publishing_configuration do
                if member_attrs.member_configuration[:log_publishing_configuration][:fabric]
                  fabric do
                    if member_attrs.member_configuration[:log_publishing_configuration][:fabric][:ca_logs]
                      ca_logs do
                        if member_attrs.member_configuration[:log_publishing_configuration][:fabric][:ca_logs][:cloudwatch]
                          cloudwatch do
                            enabled member_attrs.member_configuration[:log_publishing_configuration][:fabric][:ca_logs][:cloudwatch][:enabled]
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
            
            # Member-level tags
            if member_attrs.member_configuration[:tags] && !member_attrs.member_configuration[:tags].empty?
              tags member_attrs.member_configuration[:tags]
            end
          end
          
          # Resource-level tags
          if member_attrs.tags && !member_attrs.tags.empty?
            tags member_attrs.tags
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_managedblockchain_member',
          name: name,
          resource_attributes: member_attrs.to_h,
          outputs: {
            id: "${aws_managedblockchain_member.#{name}.id}",
            arn: "${aws_managedblockchain_member.#{name}.arn}",
            network_id: "${aws_managedblockchain_member.#{name}.network_id}",
            name: "${aws_managedblockchain_member.#{name}.member_configuration.0.name}",
            status: "${aws_managedblockchain_member.#{name}.status}",
            creation_date: "${aws_managedblockchain_member.#{name}.creation_date}",
            ca_endpoint: "${aws_managedblockchain_member.#{name}.ca_endpoint}",
            peer_endpoint: "${aws_managedblockchain_member.#{name}.peer_endpoint}",
            event_endpoint: "${aws_managedblockchain_member.#{name}.event_endpoint}",
            ordering_endpoint: "${aws_managedblockchain_member.#{name}.ordering_endpoint}"
          },
          computed: {
            member_name: member_attrs.member_name,
            member_description: member_attrs.member_description,
            is_fabric_member: member_attrs.is_fabric_member?,
            admin_username: member_attrs.admin_username,
            ca_logging_enabled: member_attrs.ca_logging_enabled?,
            is_joining_existing_network: member_attrs.is_joining_existing_network?,
            is_founding_member: member_attrs.is_founding_member?,
            member_type: member_attrs.member_type,
            estimated_monthly_cost: member_attrs.estimated_monthly_cost,
            member_capabilities: member_attrs.member_capabilities,
            security_features: member_attrs.security_features,
            compliance_features: member_attrs.compliance_features
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)