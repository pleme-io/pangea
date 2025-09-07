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
require 'pangea/resources/aws_ec2_transit_gateway_route_table_association/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EC2 Transit Gateway Route Table Association with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Transit Gateway Route Table Association attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ec2_transit_gateway_route_table_association(name, attributes = {})
        # Validate attributes using dry-struct
        association_attrs = Types::TransitGatewayRouteTableAssociationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ec2_transit_gateway_route_table_association, name) do
          # Required attachment ID
          transit_gateway_attachment_id association_attrs.transit_gateway_attachment_id
          
          # Required route table ID
          transit_gateway_route_table_id association_attrs.transit_gateway_route_table_id
          
          # Optional replacement behavior
          if association_attrs.replace_existing_association
            replace_existing_association association_attrs.replace_existing_association
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ec2_transit_gateway_route_table_association',
          name: name,
          resource_attributes: association_attrs.to_h,
          outputs: {
            id: "${aws_ec2_transit_gateway_route_table_association.#{name}.id}",
            resource_id: "${aws_ec2_transit_gateway_route_table_association.#{name}.resource_id}",
            resource_type: "${aws_ec2_transit_gateway_route_table_association.#{name}.resource_type}"
          },
          computed_attributes: {
            association_purpose: association_attrs.association_purpose,
            replaces_default_association: association_attrs.replaces_default_association?,
            routing_implications: association_attrs.routing_implications,
            security_considerations: association_attrs.security_considerations,
            operational_insights: association_attrs.operational_insights,
            troubleshooting_guide: association_attrs.troubleshooting_guide,
            estimated_change_impact: association_attrs.estimated_change_impact
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)