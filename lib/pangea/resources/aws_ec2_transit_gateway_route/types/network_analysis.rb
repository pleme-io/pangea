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
        # Network analysis methods for Transit Gateway Route attributes
        module NetworkAnalysis
          def is_blackhole_route?
            blackhole == true
          end

          def is_default_route?
            destination_cidr_block == '0.0.0.0/0'
          end

          def route_specificity
            prefix_length = destination_cidr_block.split('/')[1].to_i

            case prefix_length
            when 0..8
              'very_broad'
            when 9..16
              'broad'
            when 17..24
              'specific'
            when 25..32
              'very_specific'
            end
          end

          def is_rfc1918_private?
            ip_parts = destination_cidr_block.split('/')[0].split('.').map(&:to_i)

            return true if ip_parts[0] == 10
            return true if ip_parts[0] == 172 && (16..31).include?(ip_parts[1])
            return true if ip_parts[0] == 192 && ip_parts[1] == 168

            false
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

            analysis[:network_class] = determine_network_class(ip_parts)
            analysis
          end

          private

          def determine_network_class(ip_parts)
            case ip_parts[0]
            when 1..126
              'A'
            when 128..191
              'B'
            when 192..223
              'C'
            else
              'Special'
            end
          end
        end
      end
    end
  end
end
