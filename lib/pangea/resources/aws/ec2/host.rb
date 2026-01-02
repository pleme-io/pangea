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
      module EC2
        # Dedicated host-related EC2 resource functions
        # Includes dedicated hosts and host resource group associations
        module Host
          # Creates an EC2 dedicated host for single-tenant hardware
          #
          # @param name [Symbol] Unique name for the dedicated host resource
          # @param attributes [Hash] Configuration attributes for the dedicated host
          # @return [EC2::Ec2DedicatedHost::Ec2DedicatedHostReference] Reference to the created dedicated host
          def aws_ec2_dedicated_host(name, attributes = {})
            resource = EC2::Ec2DedicatedHost.new(
              name: name,
              synthesizer: synthesizer,
              attributes: EC2::Ec2DedicatedHost::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates an EC2 host resource group association for dedicated host management
          #
          # @param name [Symbol] Unique name for the host resource group association resource
          # @param attributes [Hash] Configuration attributes for the association
          # @return [EC2::Ec2HostResourceGroupAssociation::Ec2HostResourceGroupAssociationReference] Reference to the created association
          def aws_ec2_host_resource_group_association(name, attributes = {})
            resource = EC2::Ec2HostResourceGroupAssociation.new(
              name: name,
              synthesizer: synthesizer,
              attributes: EC2::Ec2HostResourceGroupAssociation::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end
        end
      end
    end
  end
end
