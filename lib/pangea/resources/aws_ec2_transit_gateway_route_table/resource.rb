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
require 'pangea/resources/aws_ec2_transit_gateway_route_table/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EC2 Transit Gateway Route Table with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Transit Gateway Route Table attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ec2_transit_gateway_route_table(name, attributes = {})
        # Validate attributes using dry-struct
        route_table_attrs = Types::TransitGatewayRouteTableAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ec2_transit_gateway_route_table, name) do
          # Required Transit Gateway ID
          transit_gateway_id route_table_attrs.transit_gateway_id
          
          # Apply tags if present
          if route_table_attrs.tags.any?
            tags do
              route_table_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ec2_transit_gateway_route_table',
          name: name,
          resource_attributes: route_table_attrs.to_h,
          outputs: {
            id: "${aws_ec2_transit_gateway_route_table.#{name}.id}",
            arn: "${aws_ec2_transit_gateway_route_table.#{name}.arn}",
            default_association_route_table: "${aws_ec2_transit_gateway_route_table.#{name}.default_association_route_table}",
            default_propagation_route_table: "${aws_ec2_transit_gateway_route_table.#{name}.default_propagation_route_table}",
            tags_all: "${aws_ec2_transit_gateway_route_table.#{name}.tags_all}"
          },
          computed_attributes: {
            supports_route_propagation: route_table_attrs.supports_route_propagation?,
            supports_route_association: route_table_attrs.supports_route_association?,
            estimated_monthly_cost: route_table_attrs.estimated_monthly_cost,
            route_table_purpose_analysis: route_table_attrs.route_table_purpose_analysis,
            security_considerations: route_table_attrs.security_considerations,
            routing_capabilities: route_table_attrs.routing_capabilities,
            best_practices: route_table_attrs.best_practices
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)