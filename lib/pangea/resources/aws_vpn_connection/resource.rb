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
require 'pangea/resources/aws_vpn_connection/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS VPN Connection with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] VPN connection attributes
      #   @option attributes [String] :customer_gateway_id (required) Customer Gateway ID
      #   @option attributes [String] :type (required) VPN connection type (ipsec.1)
      #   @option attributes [String] :vpn_gateway_id (optional) VPN Gateway ID (mutually exclusive with transit_gateway_id)
      #   @option attributes [String] :transit_gateway_id (optional) Transit Gateway ID (mutually exclusive with vpn_gateway_id)
      #   @option attributes [Boolean] :static_routes_only (optional) Use static routing instead of BGP
      #   @option attributes [String] :local_ipv4_network_cidr (optional) Local IPv4 CIDR for the network
      #   @option attributes [String] :remote_ipv4_network_cidr (optional) Remote IPv4 CIDR for the network
      #   @option attributes [String] :tunnel1_inside_cidr (optional) Inside CIDR block for tunnel 1
      #   @option attributes [String] :tunnel2_inside_cidr (optional) Inside CIDR block for tunnel 2
      #   @option attributes [String] :tunnel1_preshared_key (optional) Pre-shared key for tunnel 1
      #   @option attributes [String] :tunnel2_preshared_key (optional) Pre-shared key for tunnel 2
      #   @option attributes [Hash] :tags (optional) Resource tags
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_vpn_connection(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::VpnConnectionAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_vpn_connection, name) do
          customer_gateway_id attrs.customer_gateway_id
          type attrs.type
          
          # Gateway attachment (mutually exclusive)
          vpn_gateway_id attrs.vpn_gateway_id if attrs.vpn_gateway_id
          transit_gateway_id attrs.transit_gateway_id if attrs.transit_gateway_id
          
          # Optional routing and network configuration
          static_routes_only attrs.static_routes_only if attrs.static_routes_only != false
          local_ipv4_network_cidr attrs.local_ipv4_network_cidr if attrs.local_ipv4_network_cidr
          remote_ipv4_network_cidr attrs.remote_ipv4_network_cidr if attrs.remote_ipv4_network_cidr
          
          # Tunnel configuration
          tunnel1_inside_cidr attrs.tunnel1_inside_cidr if attrs.tunnel1_inside_cidr
          tunnel2_inside_cidr attrs.tunnel2_inside_cidr if attrs.tunnel2_inside_cidr
          tunnel1_preshared_key attrs.tunnel1_preshared_key if attrs.tunnel1_preshared_key
          tunnel2_preshared_key attrs.tunnel2_preshared_key if attrs.tunnel2_preshared_key
          
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
          type: 'aws_vpn_connection',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_vpn_connection.#{name}.id}",
            arn: "${aws_vpn_connection.#{name}.arn}",
            customer_gateway_configuration: "${aws_vpn_connection.#{name}.customer_gateway_configuration}",
            customer_gateway_id: "${aws_vpn_connection.#{name}.customer_gateway_id}",
            state: "${aws_vpn_connection.#{name}.state}",
            type: "${aws_vpn_connection.#{name}.type}",
            vpn_gateway_id: "${aws_vpn_connection.#{name}.vpn_gateway_id}",
            transit_gateway_id: "${aws_vpn_connection.#{name}.transit_gateway_id}",
            static_routes_only: "${aws_vpn_connection.#{name}.static_routes_only}",
            tunnel1_address: "${aws_vpn_connection.#{name}.tunnel1_address}",
            tunnel1_cgw_inside_address: "${aws_vpn_connection.#{name}.tunnel1_cgw_inside_address}",
            tunnel1_vgw_inside_address: "${aws_vpn_connection.#{name}.tunnel1_vgw_inside_address}",
            tunnel1_preshared_key: "${aws_vpn_connection.#{name}.tunnel1_preshared_key}",
            tunnel1_bgp_asn: "${aws_vpn_connection.#{name}.tunnel1_bgp_asn}",
            tunnel1_bgp_holdtime: "${aws_vpn_connection.#{name}.tunnel1_bgp_holdtime}",
            tunnel2_address: "${aws_vpn_connection.#{name}.tunnel2_address}",
            tunnel2_cgw_inside_address: "${aws_vpn_connection.#{name}.tunnel2_cgw_inside_address}",
            tunnel2_vgw_inside_address: "${aws_vpn_connection.#{name}.tunnel2_vgw_inside_address}",
            tunnel2_preshared_key: "${aws_vpn_connection.#{name}.tunnel2_preshared_key}",
            tunnel2_bgp_asn: "${aws_vpn_connection.#{name}.tunnel2_bgp_asn}",
            tunnel2_bgp_holdtime: "${aws_vpn_connection.#{name}.tunnel2_bgp_holdtime}",
            tags_all: "${aws_vpn_connection.#{name}.tags_all}"
          },
          computed_properties: {
            is_static_routing: attrs.is_static_routing?,
            uses_transit_gateway: attrs.uses_transit_gateway?,
            uses_vpn_gateway: attrs.uses_vpn_gateway?,
            gateway_attachment_type: attrs.gateway_attachment_type
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)