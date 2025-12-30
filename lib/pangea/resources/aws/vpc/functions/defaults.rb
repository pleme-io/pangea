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
      module VPC
        # Default VPC resource functions
        # Provides type-safe resource functions for managing default VPC resources
        module Defaults
          # Manages default VPC DHCP options for customizing default network behavior
          #
          # @param name [Symbol] Unique name for the default DHCP options resource
          # @param attributes [Hash] Configuration attributes for the options
          # @return [VPC::DefaultVpcDhcpOptions::DefaultVpcDhcpOptionsReference] Reference to the created options
          def aws_default_vpc_dhcp_options(name, attributes = {})
            resource = VPC::DefaultVpcDhcpOptions.new(
              name: name,
              synthesizer: synthesizer,
              attributes: VPC::DefaultVpcDhcpOptions::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Manages default network ACL for controlling default subnet access rules
          #
          # @param name [Symbol] Unique name for the default network ACL resource
          # @param attributes [Hash] Configuration attributes for the ACL
          # @return [VPC::DefaultNetworkAcl::DefaultNetworkAclReference] Reference to the created ACL
          def aws_default_network_acl(name, attributes = {})
            resource = VPC::DefaultNetworkAcl.new(
              name: name,
              synthesizer: synthesizer,
              attributes: VPC::DefaultNetworkAcl::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Manages default route table for controlling default routing behavior
          #
          # @param name [Symbol] Unique name for the default route table resource
          # @param attributes [Hash] Configuration attributes for the route table
          # @return [VPC::DefaultRouteTable::DefaultRouteTableReference] Reference to the created route table
          def aws_default_route_table(name, attributes = {})
            resource = VPC::DefaultRouteTable.new(
              name: name,
              synthesizer: synthesizer,
              attributes: VPC::DefaultRouteTable::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Manages default security group for controlling default instance access rules
          #
          # @param name [Symbol] Unique name for the default security group resource
          # @param attributes [Hash] Configuration attributes for the security group
          # @return [VPC::DefaultSecurityGroup::DefaultSecurityGroupReference] Reference to the created security group
          def aws_default_security_group(name, attributes = {})
            resource = VPC::DefaultSecurityGroup.new(
              name: name,
              synthesizer: synthesizer,
              attributes: VPC::DefaultSecurityGroup::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end
        end
      end
    end
  end
end
