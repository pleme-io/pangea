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
        # VPC Endpoint resource functions
        # Provides type-safe resource functions for VPC endpoints and endpoint services
        module Endpoints
          # Creates a VPC endpoint connection notification for monitoring endpoint state changes
          #
          # @param name [Symbol] Unique name for the connection notification resource
          # @param attributes [Hash] Configuration attributes for the notification
          # @return [VPC::VpcEndpointConnectionNotification::VpcEndpointConnectionNotificationReference] Reference to the created notification
          def aws_vpc_endpoint_connection_notification(name, attributes = {})
            resource = VPC::VpcEndpointConnectionNotification.new(
              name: name,
              synthesizer: synthesizer,
              attributes: VPC::VpcEndpointConnectionNotification::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates a VPC endpoint service allowed principal for controlling access permissions
          #
          # @param name [Symbol] Unique name for the allowed principal resource
          # @param attributes [Hash] Configuration attributes for the principal
          # @return [VPC::VpcEndpointServiceAllowedPrincipal::VpcEndpointServiceAllowedPrincipalReference] Reference to the created principal
          def aws_vpc_endpoint_service_allowed_principal(name, attributes = {})
            resource = VPC::VpcEndpointServiceAllowedPrincipal.new(
              name: name,
              synthesizer: synthesizer,
              attributes: VPC::VpcEndpointServiceAllowedPrincipal::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates a VPC endpoint connection accepter for accepting endpoint connections
          #
          # @param name [Symbol] Unique name for the connection accepter resource
          # @param attributes [Hash] Configuration attributes for the accepter
          # @return [VPC::VpcEndpointConnectionAccepter::VpcEndpointConnectionAccepterReference] Reference to the created accepter
          def aws_vpc_endpoint_connection_accepter(name, attributes = {})
            resource = VPC::VpcEndpointConnectionAccepter.new(
              name: name,
              synthesizer: synthesizer,
              attributes: VPC::VpcEndpointConnectionAccepter::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates a VPC endpoint route table association for routing endpoint traffic
          #
          # @param name [Symbol] Unique name for the route table association resource
          # @param attributes [Hash] Configuration attributes for the association
          # @return [VPC::VpcEndpointRouteTableAssociation::VpcEndpointRouteTableAssociationReference] Reference to the created association
          def aws_vpc_endpoint_route_table_association(name, attributes = {})
            resource = VPC::VpcEndpointRouteTableAssociation.new(
              name: name,
              synthesizer: synthesizer,
              attributes: VPC::VpcEndpointRouteTableAssociation::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          # Creates a VPC endpoint subnet association for subnet-level endpoint access
          #
          # @param name [Symbol] Unique name for the subnet association resource
          # @param attributes [Hash] Configuration attributes for the association
          # @return [VPC::VpcEndpointSubnetAssociation::VpcEndpointSubnetAssociationReference] Reference to the created association
          def aws_vpc_endpoint_subnet_association(name, attributes = {})
            resource = VPC::VpcEndpointSubnetAssociation.new(
              name: name,
              synthesizer: synthesizer,
              attributes: VPC::VpcEndpointSubnetAssociation::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end
        end
      end
    end
  end
end
