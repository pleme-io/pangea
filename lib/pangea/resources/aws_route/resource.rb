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
require 'pangea/resources/aws_route/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a resource to create a routing table entry (a route) in a VPC routing table.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_route(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = AWS::Types::StandaloneRouteAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_route, name) do
          route_table_id attrs.route_table_id if attrs.route_table_id
          destination_cidr_block attrs.destination_cidr_block if attrs.destination_cidr_block
          destination_ipv6_cidr_block attrs.destination_ipv6_cidr_block if attrs.destination_ipv6_cidr_block
          destination_prefix_list_id attrs.destination_prefix_list_id if attrs.destination_prefix_list_id
          carrier_gateway_id attrs.carrier_gateway_id if attrs.carrier_gateway_id
          core_network_arn attrs.core_network_arn if attrs.core_network_arn
          egress_only_gateway_id attrs.egress_only_gateway_id if attrs.egress_only_gateway_id
          gateway_id attrs.gateway_id if attrs.gateway_id
          nat_gateway_id attrs.nat_gateway_id if attrs.nat_gateway_id
          local_gateway_id attrs.local_gateway_id if attrs.local_gateway_id
          network_interface_id attrs.network_interface_id if attrs.network_interface_id
          transit_gateway_id attrs.transit_gateway_id if attrs.transit_gateway_id
          vpc_endpoint_id attrs.vpc_endpoint_id if attrs.vpc_endpoint_id
          vpc_peering_connection_id attrs.vpc_peering_connection_id if attrs.vpc_peering_connection_id
          
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
          type: 'aws_route',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_route.#{name}.id}",
            instance_id: "${aws_route.#{name}.instance_id}",
            instance_owner_id: "${aws_route.#{name}.instance_owner_id}",
            network_interface_id: "${aws_route.#{name}.network_interface_id}",
            origin: "${aws_route.#{name}.origin}",
            state: "${aws_route.#{name}.state}"
          },
          computed_properties: {
            # Computed properties from type definitions
          }
        )
      end
    end
  end
end

# Note: Registration handled by main aws.rb module
