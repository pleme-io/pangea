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
    # VPC-specific computed attributes
    class VpcComputedAttributes < BaseComputedAttributes
      # VPC-specific terraform outputs
      def cidr_block
        resource_ref.ref(:cidr_block)
      end

      def default_security_group_id
        resource_ref.ref(:default_security_group_id)
      end

      def default_route_table_id
        resource_ref.ref(:default_route_table_id)
      end

      def default_network_acl_id
        resource_ref.ref(:default_network_acl_id)
      end

      def dhcp_options_id
        resource_ref.ref(:dhcp_options_id)
      end

      def main_route_table_id
        resource_ref.ref(:main_route_table_id)
      end

      def owner_id
        resource_ref.ref(:owner_id)
      end

      # Computed helper methods
      def is_private_cidr?
        cidr = resource_ref.resource_attributes[:cidr_block]
        return false unless cidr

        ip_parts = cidr.split('/')[0].split('.').map(&:to_i)

        # 10.0.0.0/8
        return true if ip_parts[0] == 10

        # 172.16.0.0/12
        return true if ip_parts[0] == 172 && (16..31).include?(ip_parts[1])

        # 192.168.0.0/16
        return true if ip_parts[0] == 192 && ip_parts[1] == 168

        false
      end

      def estimated_subnet_capacity
        cidr_parts = resource_ref.resource_attributes[:cidr_block].split('/')
        vpc_size = cidr_parts[1].to_i

        # Estimate how many /24 subnets can fit
        case vpc_size
        when 16 then 256
        when 17 then 128
        when 18 then 64
        when 19 then 32
        when 20 then 16
        when 21 then 8
        when 22 then 4
        when 23 then 2
        when 24 then 1
        else 0
        end
      end
    end
  end
end
