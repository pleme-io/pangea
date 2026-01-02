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
    # Subnet-specific computed attributes
    class SubnetComputedAttributes < BaseComputedAttributes
      def availability_zone
        resource_ref.ref(:availability_zone)
      end

      def availability_zone_id
        resource_ref.ref(:availability_zone_id)
      end

      def cidr_block
        resource_ref.ref(:cidr_block)
      end

      def vpc_id
        resource_ref.ref(:vpc_id)
      end

      def is_public?
        resource_ref.resource_attributes[:map_public_ip_on_launch] == true
      end

      def is_private?
        !is_public?
      end

      def subnet_type
        is_public? ? 'public' : 'private'
      end

      # Calculate approximate IP capacity
      def ip_capacity
        cidr_parts = resource_ref.resource_attributes[:cidr_block].split('/')
        subnet_size = cidr_parts[1].to_i

        # AWS reserves 5 IPs per subnet
        total_ips = 2**(32 - subnet_size)
        total_ips - 5
      end
    end
  end
end
