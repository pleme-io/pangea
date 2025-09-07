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
require 'pangea/resources/aws_route_table_association/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Route Table Association with type-safe attributes
      #
      # Associates a route table with either a subnet or internet/vpn gateway.
      # Exactly one of subnet_id or gateway_id must be specified.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @option attributes [String] :route_table_id (required) The ID of the routing table
      # @option attributes [String] :subnet_id The subnet ID to associate (mutually exclusive with gateway_id)
      # @option attributes [String] :gateway_id The gateway ID for edge associations (mutually exclusive with subnet_id)
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Associate route table with subnet
      #   rtb_assoc = aws_route_table_association(:private_subnet_rtb, {
      #     route_table_id: private_rtb.id,
      #     subnet_id: private_subnet.id
      #   })
      #
      # @example Associate route table with internet gateway (edge association)
      #   rtb_assoc = aws_route_table_association(:igw_edge, {
      #     route_table_id: edge_rtb.id,
      #     gateway_id: igw.id
      #   })
      def aws_route_table_association(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = AWS::Types::RouteTableAssociationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_route_table_association, name) do
          # Required: route table ID
          route_table_id attrs.route_table_id
          
          # Either subnet_id or gateway_id (mutually exclusive)
          subnet_id attrs.subnet_id if attrs.subnet_id
          gateway_id attrs.gateway_id if attrs.gateway_id
          
          # Note: Route table associations don't support tags in AWS
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_route_table_association',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            # Route table association only provides an ID output
            id: "${aws_route_table_association.#{name}.id}",
            # Computed reference outputs for convenience
            route_table_id: "${aws_route_table_association.#{name}.route_table_id}",
            subnet_id: attrs.subnet_id ? "${aws_route_table_association.#{name}.subnet_id}" : nil,
            gateway_id: attrs.gateway_id ? "${aws_route_table_association.#{name}.gateway_id}" : nil
          }.compact,
          computed_properties: {
            # Association type information
            association_type: attrs.association_type,
            target_id: attrs.target_id,
            target_type: attrs.target_type,
            is_subnet_association: attrs.subnet_association?,
            is_gateway_association: attrs.gateway_association?
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)