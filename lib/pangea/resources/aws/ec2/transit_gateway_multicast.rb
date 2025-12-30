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
        # Transit Gateway multicast-related EC2 resource functions
        # Includes multicast domains, associations, and group members
        module TransitGatewayMulticast
          # Creates an EC2 transit gateway multicast domain for multicast traffic routing
          #
          # @param name [Symbol] Unique name for the multicast domain resource
          # @param attributes [Hash] Configuration attributes for the multicast domain
          # @return [EC2::Ec2TransitGatewayMulticastDomain::Ec2TransitGatewayMulticastDomainReference] Reference to the created domain
          def aws_ec2_transit_gateway_multicast_domain(name, attributes = {})
            resource = EC2::Ec2TransitGatewayMulticastDomain.new(
              name: name,
              synthesizer: synthesizer,
              attributes: EC2::Ec2TransitGatewayMulticastDomain::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates an EC2 transit gateway multicast domain association for subnet association
          #
          # @param name [Symbol] Unique name for the multicast domain association resource
          # @param attributes [Hash] Configuration attributes for the association
          # @return [EC2::Ec2TransitGatewayMulticastDomainAssociation::Ec2TransitGatewayMulticastDomainAssociationReference] Reference to the created association
          def aws_ec2_transit_gateway_multicast_domain_association(name, attributes = {})
            resource = EC2::Ec2TransitGatewayMulticastDomainAssociation.new(
              name: name,
              synthesizer: synthesizer,
              attributes: EC2::Ec2TransitGatewayMulticastDomainAssociation::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates an EC2 transit gateway multicast group member for multicast group management
          #
          # @param name [Symbol] Unique name for the multicast group member resource
          # @param attributes [Hash] Configuration attributes for the group member
          # @return [EC2::Ec2TransitGatewayMulticastGroupMember::Ec2TransitGatewayMulticastGroupMemberReference] Reference to the created group member
          def aws_ec2_transit_gateway_multicast_group_member(name, attributes = {})
            resource = EC2::Ec2TransitGatewayMulticastGroupMember.new(
              name: name,
              synthesizer: synthesizer,
              attributes: EC2::Ec2TransitGatewayMulticastGroupMember::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end
        end
      end
    end
  end
end
