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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # VPN tunnel options for detailed tunnel configuration
      class VpnTunnelOptions < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :tunnel_inside_cidr, Resources::Types::CidrBlock.optional
        attribute :preshared_key, Resources::Types::String.optional
        attributephase1_dh_group_numbers :, Resources::Types::Array.of(Types::Integer).optional
        attributephase2_dh_group_numbers :, Resources::Types::Array.of(Types::Integer).optional
        attributephase1_encryption_algorithms :, Resources::Types::Array.of(Types::String).optional
        attributephase2_encryption_algorithms :, Resources::Types::Array.of(Types::String).optional
        attributephase1_integrity_algorithms :, Resources::Types::Array.of(Types::String).optional
        attributephase2_integrity_algorithms :, Resources::Types::Array.of(Types::String).optional
        attributephase1_lifetime_seconds :, Resources::Types::Integer.constrained(gteq: 900, lteq: 28800).optional
        attributephase2_lifetime_seconds :, Resources::Types::Integer.constrained(gteq: 900, lteq: 3600).optional
        attribute :rekey_margin_time_seconds, Resources::Types::Integer.constrained(gteq: 60, lteq: 1800).optional
        attribute :rekey_fuzz_percentage, Resources::Types::Integer.constrained(gteq: 0, lteq: 100).optional
        attribute :replay_window_size, Resources::Types::Integer.constrained(gteq: 64, lteq: 2048).optional
        attribute :dpd_timeout_seconds, Resources::Types::Integer.constrained(gteq: 0, lteq: 3600).optional
        attribute :dpd_timeout_action, Resources::Types::String.enum('clear', 'none', 'restart').optional
        attribute :startup_action, Resources::Types::String.enum('add', 'start').optional
      end
      
      # Type-safe attributes for AwsVpnConnection resources
      class VpnConnectionAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # Required attributes
        attribute :customer_gateway_id, Resources::Types::String
        attribute :type, Resources::Types::VpnConnectionType
        
        # Optional attributes
        attribute :vpn_gateway_id, Resources::Types::String.optional
        attribute :transit_gateway_id, Resources::Types::String.optional
        attribute :static_routes_only, Resources::Types::Bool.default(false)
        attributelocal_ipv4_network_cidr :, Resources::Types::CidrBlock.optional
        attributeremote_ipv4_network_cidr :, Resources::Types::CidrBlock.optional
        attributetunnel1_inside_cidr :, Resources::Types::CidrBlock.optional
        attributetunnel2_inside_cidr :, Resources::Types::CidrBlock.optional
        attributetunnel1_preshared_key :, Resources::Types::String.optional
        attributetunnel2_preshared_key :, Resources::Types::String.optional
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = attributes.is_a?(Hash) ? attributes : {}
          
          # Validate customer gateway ID format
          if attrs[:customer_gateway_id]
            unless attrs[:customer_gateway_id].match(/\Acgw-[0-9a-f]{8,17}\z/)
              raise Dry::Struct::Error, "customer_gateway_id must be a valid Customer Gateway ID (cgw-*)"
            end
          end
          
          # Validate VPN gateway ID format if provided
          if attrs[:vpn_gateway_id]
            unless attrs[:vpn_gateway_id].match(/\Avgw-[0-9a-f]{8,17}\z/)
              raise Dry::Struct::Error, "vpn_gateway_id must be a valid VPN Gateway ID (vgw-*)"
            end
          end
          
          # Validate transit gateway ID format if provided
          if attrs[:transit_gateway_id]
            unless attrs[:transit_gateway_id].match(/\Atgw-[0-9a-f]{8,17}\z/)
              raise Dry::Struct::Error, "transit_gateway_id must be a valid Transit Gateway ID (tgw-*)"
            end
          end
          
          # Ensure either vpn_gateway_id or transit_gateway_id is provided
          unless attrs[:vpn_gateway_id] || attrs[:transit_gateway_id]
            raise Dry::Struct::Error, "Either vpn_gateway_id or transit_gateway_id must be specified"
          end
          
          # Ensure both vpn_gateway_id and transit_gateway_id are not provided
          if attrs[:vpn_gateway_id] && attrs[:transit_gateway_id]
            raise Dry::Struct::Error, "Cannot specify both vpn_gateway_id and transit_gateway_id"
          end
          
          super(attrs)
        end

        # Computed properties
        def is_static_routing?
          static_routes_only
        end
        
        def uses_transit_gateway?
          !transit_gateway_id.nil?
        end
        
        def uses_vpn_gateway?
          !vpn_gateway_id.nil?
        end
        
        def gateway_attachment_type
          return 'transit_gateway' if transit_gateway_id
          return 'vpn_gateway' if vpn_gateway_id
          'none'
        end
      end
    end
      end
    end
  end
end