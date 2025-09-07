# frozen_string_literal: true

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