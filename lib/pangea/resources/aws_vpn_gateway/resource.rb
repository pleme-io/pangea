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
require 'pangea/resources/aws_vpn_gateway/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS VPN Gateway with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] VPN Gateway attributes
      #   @option attributes [String] :vpc_id (optional) VPC ID to attach the gateway to
      #   @option attributes [String] :availability_zone (optional) AZ for the gateway (default: multi-AZ)
      #   @option attributes [String] :type (optional) Gateway type (default: ipsec.1)
      #   @option attributes [Integer] :amazon_side_asn (optional) Amazon-side BGP ASN
      #   @option attributes [Hash] :tags (optional) Resource tags
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_vpn_gateway(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::VpnGatewayAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_vpn_gateway, name) do
          # Optional VPC attachment
          vpc_id attrs.vpc_id if attrs.vpc_id
          
          # Optional availability zone (if not specified, uses multi-AZ)
          availability_zone attrs.availability_zone if attrs.availability_zone
          
          # Gateway type (defaults to ipsec.1)
          type attrs.type
          
          # Optional Amazon-side BGP ASN
          amazon_side_asn attrs.amazon_side_asn if attrs.amazon_side_asn
          
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
          type: 'aws_vpn_gateway',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_vpn_gateway.#{name}.id}",
            arn: "${aws_vpn_gateway.#{name}.arn}",
            type: "${aws_vpn_gateway.#{name}.type}",
            availability_zone: "${aws_vpn_gateway.#{name}.availability_zone}",
            state: "${aws_vpn_gateway.#{name}.state}",
            vpc_id: "${aws_vpn_gateway.#{name}.vpc_id}",
            amazon_side_asn: "${aws_vpn_gateway.#{name}.amazon_side_asn}",
            tags_all: "${aws_vpn_gateway.#{name}.tags_all}"
          },
          computed_properties: {
            has_vpc_attachment: attrs.has_vpc_attachment?,
            uses_custom_asn: attrs.uses_custom_asn?,
            is_multi_az_capable: attrs.is_multi_az_capable?,
            attachment_type: attrs.attachment_type
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)