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
require 'pangea/resources/aws_ec2_transit_gateway_route_table_propagation/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EC2 Transit Gateway Route Table Propagation with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Transit Gateway Route Table Propagation attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ec2_transit_gateway_route_table_propagation(name, attributes = {})
        # Validate attributes using dry-struct
        propagation_attrs = Types::TransitGatewayRouteTablePropagationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ec2_transit_gateway_route_table_propagation, name) do
          # Required attachment ID (source of routes)
          transit_gateway_attachment_id propagation_attrs.transit_gateway_attachment_id
          
          # Required route table ID (destination for routes)
          transit_gateway_route_table_id propagation_attrs.transit_gateway_route_table_id
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ec2_transit_gateway_route_table_propagation',
          name: name,
          resource_attributes: propagation_attrs.to_h,
          outputs: {
            id: "${aws_ec2_transit_gateway_route_table_propagation.#{name}.id}",
            resource_id: "${aws_ec2_transit_gateway_route_table_propagation.#{name}.resource_id}",
            resource_type: "${aws_ec2_transit_gateway_route_table_propagation.#{name}.resource_type}"
          },
          computed_attributes: {
            propagation_purpose: propagation_attrs.propagation_purpose,
            route_advertisement_behavior: propagation_attrs.route_advertisement_behavior,
            propagation_implications: propagation_attrs.propagation_implications,
            security_considerations: propagation_attrs.security_considerations,
            operational_insights: propagation_attrs.operational_insights,
            route_propagation_scenarios: propagation_attrs.route_propagation_scenarios,
            troubleshooting_guide: propagation_attrs.troubleshooting_guide,
            estimated_impact: propagation_attrs.estimated_impact
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)