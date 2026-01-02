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
    # EC2 Instance-specific computed attributes
    class InstanceComputedAttributes < BaseComputedAttributes
      def public_ip
        resource_ref.ref(:public_ip)
      end

      def private_ip
        resource_ref.ref(:private_ip)
      end

      def public_dns
        resource_ref.ref(:public_dns)
      end

      def private_dns
        resource_ref.ref(:private_dns)
      end

      def instance_state
        resource_ref.ref(:instance_state)
      end

      def subnet_id
        resource_ref.ref(:subnet_id)
      end

      def vpc_security_group_ids
        resource_ref.ref(:vpc_security_group_ids)
      end

      def instance_type
        resource_ref.resource_attributes[:instance_type]
      end

      def ami
        resource_ref.resource_attributes[:ami]
      end

      # Helper methods
      def will_have_public_ip?
        # If explicitly set to false, respect that
        return false if resource_ref.resource_attributes[:associate_public_ip_address] == false

        # Otherwise, true if explicitly set to true or in a public subnet
        resource_ref.resource_attributes[:associate_public_ip_address] == true ||
          resource_ref.resource_attributes[:subnet_id]&.include?('public')
      end

      def compute_family
        instance_type = resource_ref.resource_attributes[:instance_type]
        instance_type.split('.').first if instance_type
      end

      def compute_size
        instance_type = resource_ref.resource_attributes[:instance_type]
        instance_type.split('.').last if instance_type
      end
    end
  end
end
