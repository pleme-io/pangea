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

require_relative 'core'

module Pangea
  module Resources
    module Types
      # VPN-related types
      VpnConnectionType = String.enum('ipsec.1')
      VpnGatewayType = String.enum('ipsec.1')
      VpnTunnelProtocol = String.enum('ikev1', 'ikev2')

      # Transit Gateway ASN validation
      TransitGatewayAsn = Integer.constructor { |value|
        if (64512..65534).include?(value)
          return value
        end
        if (4200000000..4294967294).include?(value)
          return value
        end
        reserved_asns = [7224, 9059, 10124, 17943]
        if reserved_asns.include?(value)
          raise Dry::Types::ConstraintError, "ASN #{value} is reserved by AWS"
        end
        raise Dry::Types::ConstraintError, "Transit Gateway ASN must be in range 64512-65534 (16-bit) or 4200000000-4294967294 (32-bit)"
      }

      TransitGatewayDefaultRouteTableAssociation = String.default('enable').enum('enable', 'disable')
      TransitGatewayDefaultRouteTablePropagation = String.default('enable').enum('enable', 'disable')
      TransitGatewayDnsSupport = String.default('enable').enum('enable', 'disable')
      TransitGatewayMulticastSupport = String.default('disable').enum('enable', 'disable')
      TransitGatewayVpnEcmpSupport = String.default('enable').enum('enable', 'disable')

      TransitGatewayAttachmentResourceType = String.enum('vpc', 'vpn', 'direct-connect-gateway', 'peering', 'tgw-peering')
      TransitGatewayRouteType = String.enum('static', 'propagated')
      TransitGatewayRouteState = String.enum('active', 'blackhole')

      TransitGatewayVpcAttachmentDnsSupport = String.default('enable').enum('enable', 'disable')
      TransitGatewayVpcAttachmentIpv6Support = String.default('disable').enum('enable', 'disable')
      TransitGatewayVpcAttachmentApplianceModeSupport = String.default('disable').enum('enable', 'disable')

      # CIDR block validation for Transit Gateway routes
      TransitGatewayCidrBlock = String.constructor { |value|
        if value.match?(/\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}\z/)
          ip, prefix = value.split('/')
          ip_parts = ip.split('.').map(&:to_i)
          prefix_int = prefix.to_i
          unless ip_parts.all? { |octet| (0..255).include?(octet) }
            raise Dry::Types::ConstraintError, "Invalid IP address in CIDR block: #{value}"
          end
          unless (0..32).include?(prefix_int)
            raise Dry::Types::ConstraintError, "Invalid prefix length in CIDR block: #{value}. Must be 0-32."
          end
          return value
        end
        return value if value == '0.0.0.0/0'
        raise Dry::Types::ConstraintError, "Transit Gateway CIDR block must be valid CIDR notation or '0.0.0.0/0'"
      }
    end
  end
end
