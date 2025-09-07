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
        # Transit Gateway Route resource attributes with validation
        class TransitGatewayRouteAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :destination_cidr_block, Resources::Types::TransitGatewayCidrBlock
          attribute :transit_gateway_route_table_id, Resources::Types::String
          attribute? :blackhole, Resources::Types::Bool.default(false)
          attribute? :transit_gateway_attachment_id, Resources::Types::String.optional
          
          # Custom validation for route configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate route table ID format
            if attrs[:transit_gateway_route_table_id] && !attrs[:transit_gateway_route_table_id].match?(/\Atgw-rtb-[0-9a-f]{8,17}\z/)
              raise Dry::Struct::Error, "Invalid Transit Gateway Route Table ID format: #{attrs[:transit_gateway_route_table_id]}. Expected format: tgw-rtb-xxxxxxxx"
            end
            
            # Validate attachment ID format if provided
            if attrs[:transit_gateway_attachment_id] && !attrs[:transit_gateway_attachment_id].match?(/\Atgw-attach-[0-9a-f]{8,17}\z/)
              raise Dry::Struct::Error, "Invalid Transit Gateway Attachment ID format: #{attrs[:transit_gateway_attachment_id]}. Expected format: tgw-attach-xxxxxxxx"
            end
            
            # Validate blackhole route logic
            if attrs[:blackhole] == true && attrs[:transit_gateway_attachment_id]
              raise Dry::Struct::Error, "Blackhole routes cannot specify a transit_gateway_attachment_id. Set blackhole: true without attachment_id for traffic drop."
            end
            
            if attrs[:blackhole] != true && !attrs[:transit_gateway_attachment_id]
              raise Dry::Struct::Error, "Non-blackhole routes must specify a transit_gateway_attachment_id for traffic forwarding."
            end
            
            super(attrs)
          end
          
          # Computed properties
          def is_blackhole_route?
            blackhole == true
          end
          
          def is_default_route?
            destination_cidr_block == '0.0.0.0/0'
          end
          
          def route_specificity
            # Calculate route specificity based on CIDR prefix length
            prefix_length = destination_cidr_block.split('/')[1].to_i
            
            case prefix_length
            when 0..8
              'very_broad'      # /0 to /8 - very broad routes
            when 9..16
              'broad'          # /9 to /16 - broad network routes
            when 17..24
              'specific'       # /17 to /24 - specific subnet routes
            when 25..32
              'very_specific'  # /25 to /32 - host or very specific routes
            end
          end
          
          def network_analysis
            ip, prefix = destination_cidr_block.split('/')
            ip_parts = ip.split('.').map(&:to_i)
            prefix_int = prefix.to_i
            
            analysis = {
              ip_address: ip,
              prefix_length: prefix_int,
              network_size: 2**(32 - prefix_int),
              is_rfc1918_private: is_rfc1918_private?,
              is_default_route: is_default_route?,
              specificity: route_specificity
            }
            
            # Add network class information
            if ip_parts[0] >= 1 && ip_parts[0] <= 126
              analysis[:network_class] = 'A'
            elsif ip_parts[0] >= 128 && ip_parts[0] <= 191
              analysis[:network_class] = 'B'
            elsif ip_parts[0] >= 192 && ip_parts[0] <= 223
              analysis[:network_class] = 'C'
            else
              analysis[:network_class] = 'Special'
            end
            
            analysis
          end
          
          def is_rfc1918_private?
            ip_parts = destination_cidr_block.split('/')[0].split('.').map(&:to_i)
            
            # 10.0.0.0/8
            return true if ip_parts[0] == 10
            
            # 172.16.0.0/12
            return true if ip_parts[0] == 172 && (16..31).include?(ip_parts[1])
            
            # 192.168.0.0/16
            return true if ip_parts[0] == 192 && ip_parts[1] == 168
            
            false
          end
          
          def security_implications
            implications = []
            
            if is_default_route?
              if is_blackhole_route?
                implications << "Default route blackhole - all unmatched traffic will be dropped"
              else
                implications << "Default route - all unmatched traffic will be forwarded to specified attachment"
                implications << "Default routes have security implications - ensure target attachment is properly secured"
              end
            end
            
            if is_blackhole_route?
              implications << "Blackhole route - traffic to #{destination_cidr_block} will be silently dropped"
              implications << "Blackhole routes are useful for security but may cause connectivity issues if misconfigured"
            else
              implications << "Forward route - traffic to #{destination_cidr_block} will be sent to attachment #{transit_gateway_attachment_id}"
            end
            
            if is_rfc1918_private?
              implications << "Route targets private address space (RFC 1918)"
            else
              implications << "Route targets public/special address space - verify this is intended"
            end
            
            case route_specificity
            when 'very_broad'
              implications << "Very broad route (#{destination_cidr_block}) - affects large address ranges"
            when 'very_specific'
              implications << "Very specific route (#{destination_cidr_block}) - targets small address range or host"
            end
            
            implications
          end
          
          def route_purpose_analysis
            purposes = []
            
            if is_default_route?
              if is_blackhole_route?
                purposes << 'default_deny'
              else
                purposes << 'default_gateway'
              end
            end
            
            if is_rfc1918_private?
              purposes << 'private_network_routing'
            else
              purposes << 'public_network_routing'
            end
            
            if is_blackhole_route?
              purposes << 'traffic_blocking'
            else
              purposes << 'traffic_forwarding'
            end
            
            case route_specificity
            when 'very_specific'
              purposes << 'host_routing'
            when 'specific'
              purposes << 'subnet_routing'
            when 'broad'
              purposes << 'network_routing'
            when 'very_broad'
              purposes << 'aggregate_routing'
            end
            
            purposes
          end
          
          def best_practices
            practices = []
            
            if is_default_route?
              practices << "Default routes should be carefully managed and documented"
              practices << "Consider using specific routes instead of default when possible"
              if !is_blackhole_route?
                practices << "Ensure default route target can handle all unmatched traffic"
              end
            end
            
            if is_blackhole_route?
              practices << "Document blackhole routes for operational clarity"
              practices << "Monitor traffic that hits blackhole routes for troubleshooting"
              practices << "Consider logging dropped traffic for security analysis"
            end
            
            case route_specificity
            when 'very_broad'
              practices << "Very broad routes should be used sparingly and with careful consideration"
            when 'very_specific'
              practices << "Host-specific routes may indicate routing inefficiency or special requirements"
            end
            
            practices << "Use descriptive resource names to indicate route purpose"
            practices << "Document route dependencies and expected traffic patterns"
            practices << "Implement route change management processes for production environments"
            
            practices
          end
        end
      end
    end
  end
end