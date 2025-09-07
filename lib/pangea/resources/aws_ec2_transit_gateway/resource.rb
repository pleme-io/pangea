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
require 'pangea/resources/aws_ec2_transit_gateway/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS EC2 Transit Gateway with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Transit Gateway attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ec2_transit_gateway(name, attributes = {})
        # Validate attributes using dry-struct
        tgw_attrs = Types::TransitGatewayAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ec2_transit_gateway, name) do
          # Optional amazon_side_asn
          if tgw_attrs.amazon_side_asn
            amazon_side_asn tgw_attrs.amazon_side_asn
          end
          
          # Auto accept shared attachments
          if tgw_attrs.auto_accept_shared_attachments
            auto_accept_shared_attachments tgw_attrs.auto_accept_shared_attachments
          end
          
          # Default route table association
          if tgw_attrs.default_route_table_association
            default_route_table_association tgw_attrs.default_route_table_association
          end
          
          # Default route table propagation
          if tgw_attrs.default_route_table_propagation
            default_route_table_propagation tgw_attrs.default_route_table_propagation
          end
          
          # Description
          if tgw_attrs.description
            description tgw_attrs.description
          end
          
          # DNS support
          if tgw_attrs.dns_support
            dns_support tgw_attrs.dns_support
          end
          
          # Multicast support
          if tgw_attrs.multicast_support
            multicast_support tgw_attrs.multicast_support
          end
          
          # VPN ECMP support
          if tgw_attrs.vpn_ecmp_support
            vpn_ecmp_support tgw_attrs.vpn_ecmp_support
          end
          
          # Apply tags if present
          if tgw_attrs.tags.any?
            tags do
              tgw_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ec2_transit_gateway',
          name: name,
          resource_attributes: tgw_attrs.to_h,
          outputs: {
            id: "${aws_ec2_transit_gateway.#{name}.id}",
            arn: "${aws_ec2_transit_gateway.#{name}.arn}",
            association_default_route_table_id: "${aws_ec2_transit_gateway.#{name}.association_default_route_table_id}",
            owner_id: "${aws_ec2_transit_gateway.#{name}.owner_id}",
            propagation_default_route_table_id: "${aws_ec2_transit_gateway.#{name}.propagation_default_route_table_id}",
            transit_gateway_cidr_blocks: "${aws_ec2_transit_gateway.#{name}.transit_gateway_cidr_blocks}",
            tags_all: "${aws_ec2_transit_gateway.#{name}.tags_all}"
          },
          computed_attributes: {
            supports_cross_region_peering: tgw_attrs.supports_cross_region_peering?,
            supports_dx_gateway_attachment: tgw_attrs.supports_dx_gateway_attachment?,
            estimated_monthly_cost: tgw_attrs.estimated_monthly_cost,
            security_considerations: tgw_attrs.security_considerations,
            is_hub_and_spoke_optimized: tgw_attrs.is_hub_and_spoke_optimized?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)