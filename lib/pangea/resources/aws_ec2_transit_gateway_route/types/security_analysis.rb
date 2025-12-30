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

module Pangea
  module Resources
    module AWS
      module Types
        # Security analysis methods for Transit Gateway Route attributes
        module SecurityAnalysis
          def security_implications
            implications = []
            implications.concat(default_route_implications) if is_default_route?
            implications.concat(blackhole_implications)
            implications.concat(address_space_implications)
            implications.concat(specificity_implications)
            implications
          end

          def route_purpose_analysis
            purposes = []
            purposes.concat(default_route_purposes) if is_default_route?
            purposes << (is_rfc1918_private? ? 'private_network_routing' : 'public_network_routing')
            purposes << (is_blackhole_route? ? 'traffic_blocking' : 'traffic_forwarding')
            purposes << specificity_purpose
            purposes
          end

          def best_practices
            practices = []
            practices.concat(default_route_practices) if is_default_route?
            practices.concat(blackhole_practices) if is_blackhole_route?
            practices.concat(specificity_practices)
            practices.concat(general_practices)
            practices
          end

          private

          def default_route_implications
            if is_blackhole_route?
              ['Default route blackhole - all unmatched traffic will be dropped']
            else
              [
                'Default route - all unmatched traffic will be forwarded to specified attachment',
                'Default routes have security implications - ensure target attachment is properly secured'
              ]
            end
          end

          def blackhole_implications
            if is_blackhole_route?
              [
                "Blackhole route - traffic to #{destination_cidr_block} will be silently dropped",
                'Blackhole routes are useful for security but may cause connectivity issues if misconfigured'
              ]
            else
              ["Forward route - traffic to #{destination_cidr_block} will be sent to attachment #{transit_gateway_attachment_id}"]
            end
          end

          def address_space_implications
            if is_rfc1918_private?
              ['Route targets private address space (RFC 1918)']
            else
              ['Route targets public/special address space - verify this is intended']
            end
          end

          def specificity_implications
            case route_specificity
            when 'very_broad'
              ["Very broad route (#{destination_cidr_block}) - affects large address ranges"]
            when 'very_specific'
              ["Very specific route (#{destination_cidr_block}) - targets small address range or host"]
            else
              []
            end
          end

          def default_route_purposes
            [is_blackhole_route? ? 'default_deny' : 'default_gateway']
          end

          def specificity_purpose
            case route_specificity
            when 'very_specific' then 'host_routing'
            when 'specific' then 'subnet_routing'
            when 'broad' then 'network_routing'
            when 'very_broad' then 'aggregate_routing'
            end
          end

          def default_route_practices
            practices = [
              'Default routes should be carefully managed and documented',
              'Consider using specific routes instead of default when possible'
            ]
            practices << 'Ensure default route target can handle all unmatched traffic' unless is_blackhole_route?
            practices
          end

          def blackhole_practices
            [
              'Document blackhole routes for operational clarity',
              'Monitor traffic that hits blackhole routes for troubleshooting',
              'Consider logging dropped traffic for security analysis'
            ]
          end

          def specificity_practices
            case route_specificity
            when 'very_broad'
              ['Very broad routes should be used sparingly and with careful consideration']
            when 'very_specific'
              ['Host-specific routes may indicate routing inefficiency or special requirements']
            else
              []
            end
          end

          def general_practices
            [
              'Use descriptive resource names to indicate route purpose',
              'Document route dependencies and expected traffic patterns',
              'Implement route change management processes for production environments'
            ]
          end
        end
      end
    end
  end
end
