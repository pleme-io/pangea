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
require 'pangea/resources/aws_vpc_peering_connection/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS VPC Peering Connection with type-safe attributes
      #
      # Enables private connectivity between two VPCs in the same or different regions/accounts.
      # Supports cross-account and cross-region peering with proper DNS resolution configuration.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_vpc_peering_connection(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Pangea::Resources::Types::VpcPeeringConnectionAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_vpc_peering_connection, name) do
          # Required VPC configuration
          vpc_id attrs.vpc_id
          peer_vpc_id attrs.peer_vpc_id
          
          # Cross-account/region configuration
          peer_owner_id attrs.peer_owner_id if attrs.peer_owner_id
          peer_region attrs.peer_region if attrs.peer_region
          
          # Auto-accept configuration (same account only)
          auto_accept attrs.auto_accept if attrs.auto_accept
          
          # Accepter configuration block
          if attrs.accepter.any?
            accepter do
              attrs.accepter.each do |key, value|
                case key
                when :allow_remote_vpc_dns_resolution
                  allow_remote_vpc_dns_resolution value if value != false
                end
              end
            end
          end
          
          # Requester configuration block
          if attrs.requester.any?
            requester do
              attrs.requester.each do |key, value|
                case key
                when :allow_remote_vpc_dns_resolution
                  allow_remote_vpc_dns_resolution value if value != false
                end
              end
            end
          end
          
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
        Pangea::Resources::ResourceReference.new(
          type: 'aws_vpc_peering_connection',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_vpc_peering_connection.#{name}.id}",
            arn: "${aws_vpc_peering_connection.#{name}.arn}",
            status: "${aws_vpc_peering_connection.#{name}.status}",
            accept_status: "${aws_vpc_peering_connection.#{name}.accept_status}",
            vpc_id: "${aws_vpc_peering_connection.#{name}.vpc_id}",
            peer_vpc_id: "${aws_vpc_peering_connection.#{name}.peer_vpc_id}",
            peer_owner_id: "${aws_vpc_peering_connection.#{name}.peer_owner_id}",
            peer_region: "${aws_vpc_peering_connection.#{name}.peer_region}",
            accepter: "${aws_vpc_peering_connection.#{name}.accepter}",
            requester: "${aws_vpc_peering_connection.#{name}.requester}",
            tags_all: "${aws_vpc_peering_connection.#{name}.tags_all}"
          },
          computed_properties: {
            cross_account: attrs.cross_account?,
            cross_region: attrs.cross_region?,
            accepter_dns_resolution: attrs.accepter_dns_resolution?,
            requester_dns_resolution: attrs.requester_dns_resolution?,
            connection_type: attrs.connection_type,
            connection_type_description: attrs.connection_type_description
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)