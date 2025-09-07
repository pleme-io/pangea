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
require 'pangea/resources/aws_ec2_transit_gateway_route/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EC2 Transit Gateway Route with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Transit Gateway Route attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ec2_transit_gateway_route(name, attributes = {})
        # Validate attributes using dry-struct
        route_attrs = Types::TransitGatewayRouteAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ec2_transit_gateway_route, name) do
          # Required destination CIDR block
          destination_cidr_block route_attrs.destination_cidr_block
          
          # Required route table ID
          transit_gateway_route_table_id route_attrs.transit_gateway_route_table_id
          
          # Conditional routing configuration
          if route_attrs.is_blackhole_route?
            # Blackhole route - traffic is dropped
            blackhole route_attrs.blackhole
          else
            # Forward route - traffic is sent to attachment
            transit_gateway_attachment_id route_attrs.transit_gateway_attachment_id
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ec2_transit_gateway_route',
          name: name,
          resource_attributes: route_attrs.to_h,
          outputs: {
            # Transit Gateway routes don't have standard outputs like id/arn
            # The route is identified by the combination of route table and destination CIDR
            route_table_id: "${aws_ec2_transit_gateway_route.#{name}.transit_gateway_route_table_id}",
            destination_cidr_block: "${aws_ec2_transit_gateway_route.#{name}.destination_cidr_block}",
            state: "${aws_ec2_transit_gateway_route.#{name}.state}"
          },
          computed_attributes: {
            is_blackhole_route: route_attrs.is_blackhole_route?,
            is_default_route: route_attrs.is_default_route?,
            route_specificity: route_attrs.route_specificity,
            network_analysis: route_attrs.network_analysis,
            is_rfc1918_private: route_attrs.is_rfc1918_private?,
            security_implications: route_attrs.security_implications,
            route_purpose_analysis: route_attrs.route_purpose_analysis,
            best_practices: route_attrs.best_practices
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)