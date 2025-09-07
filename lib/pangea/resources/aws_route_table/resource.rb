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
require 'pangea/resources/aws_route_table/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Route Table with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Route Table attributes
      # @option attributes [String] :vpc_id The VPC ID (required)
      # @option attributes [Array<Hash>] :routes Array of route definitions
      # @option attributes [Hash] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Create a route table with internet gateway route
      #   rt = aws_route_table(:public, {
      #     vpc_id: vpc.id,
      #     routes: [{
      #       cidr_block: "0.0.0.0/0",
      #       gateway_id: igw.id
      #     }],
      #     tags: { Name: "public-route-table" }
      #   })
      #
      # @example Create a route table with NAT gateway route
      #   rt = aws_route_table(:private, {
      #     vpc_id: vpc.id,
      #     routes: [{
      #       cidr_block: "0.0.0.0/0",
      #       nat_gateway_id: nat.id
      #     }],
      #     tags: { Name: "private-route-table" }
      #   })
      def aws_route_table(name, attributes = {})
        # Validate attributes using dry-struct
        rt_attrs = AWS::Types::RouteTableAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_route_table, name) do
          vpc_id rt_attrs.vpc_id
          
          # Add routes if specified
          rt_attrs.routes.each do |route_attrs|
            route do
              cidr_block route_attrs.cidr_block if route_attrs.cidr_block
              ipv6_cidr_block route_attrs.ipv6_cidr_block if route_attrs.ipv6_cidr_block
              gateway_id route_attrs.gateway_id if route_attrs.gateway_id
              nat_gateway_id route_attrs.nat_gateway_id if route_attrs.nat_gateway_id
              network_interface_id route_attrs.network_interface_id if route_attrs.network_interface_id
              transit_gateway_id route_attrs.transit_gateway_id if route_attrs.transit_gateway_id
              vpc_peering_connection_id route_attrs.vpc_peering_connection_id if route_attrs.vpc_peering_connection_id
              vpc_endpoint_id route_attrs.vpc_endpoint_id if route_attrs.vpc_endpoint_id
              egress_only_gateway_id route_attrs.egress_only_gateway_id if route_attrs.egress_only_gateway_id
            end
          end
          
          # Apply tags if present
          if rt_attrs.tags.any?
            tags do
              rt_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_route_table',
          name: name,
          resource_attributes: rt_attrs.to_h,
          outputs: {
            id: "${aws_route_table.#{name}.id}",
            arn: "${aws_route_table.#{name}.arn}",
            owner_id: "${aws_route_table.#{name}.owner_id}",
            route_table_id: "${aws_route_table.#{name}.id}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)