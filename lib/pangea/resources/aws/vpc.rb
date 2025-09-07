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


require_relative 'vpc/vpc_endpoint_connection_notification'
require_relative 'vpc/vpc_endpoint_service_allowed_principal'
require_relative 'vpc/vpc_endpoint_connection_accepter'
require_relative 'vpc/vpc_endpoint_route_table_association'
require_relative 'vpc/vpc_endpoint_subnet_association'
require_relative 'vpc/vpc_peering_connection_options'
require_relative 'vpc/vpc_peering_connection_accepter'
require_relative 'vpc/vpc_dhcp_options_association'
require_relative 'vpc/vpc_network_performance_metric_subscription'
require_relative 'vpc/vpc_security_group_egress_rule'
require_relative 'vpc/vpc_security_group_ingress_rule'
require_relative 'vpc/default_vpc_dhcp_options'
require_relative 'vpc/default_network_acl'
require_relative 'vpc/default_route_table'
require_relative 'vpc/default_security_group'

module Pangea
  module Resources
    module AWS
      # AWS VPC Extended service module
      # Provides type-safe resource functions for advanced VPC networking, endpoints, and defaults
      module VPC
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

        # Creates VPC peering connection options for customizing peering behavior
        #
        # @param name [Symbol] Unique name for the peering connection options resource
        # @param attributes [Hash] Configuration attributes for the options
        # @return [VPC::VpcPeeringConnectionOptions::VpcPeeringConnectionOptionsReference] Reference to the created options
        def aws_vpc_peering_connection_options(name, attributes = {})
          resource = VPC::VpcPeeringConnectionOptions.new(
            name: name,
            synthesizer: synthesizer,
            attributes: VPC::VpcPeeringConnectionOptions::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a VPC peering connection accepter for accepting cross-account/region peering
        #
        # @param name [Symbol] Unique name for the peering connection accepter resource
        # @param attributes [Hash] Configuration attributes for the accepter
        # @return [VPC::VpcPeeringConnectionAccepter::VpcPeeringConnectionAccepterReference] Reference to the created accepter
        def aws_vpc_peering_connection_accepter(name, attributes = {})
          resource = VPC::VpcPeeringConnectionAccepter.new(
            name: name,
            synthesizer: synthesizer,
            attributes: VPC::VpcPeeringConnectionAccepter::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a VPC DHCP options association for linking DHCP options to a VPC
        #
        # @param name [Symbol] Unique name for the DHCP options association resource
        # @param attributes [Hash] Configuration attributes for the association
        # @return [VPC::VpcDhcpOptionsAssociation::VpcDhcpOptionsAssociationReference] Reference to the created association
        def aws_vpc_dhcp_options_association(name, attributes = {})
          resource = VPC::VpcDhcpOptionsAssociation.new(
            name: name,
            synthesizer: synthesizer,
            attributes: VPC::VpcDhcpOptionsAssociation::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a VPC network performance metric subscription for monitoring network metrics
        #
        # @param name [Symbol] Unique name for the metric subscription resource
        # @param attributes [Hash] Configuration attributes for the subscription
        # @return [VPC::VpcNetworkPerformanceMetricSubscription::VpcNetworkPerformanceMetricSubscriptionReference] Reference to the created subscription
        def aws_vpc_network_performance_metric_subscription(name, attributes = {})
          resource = VPC::VpcNetworkPerformanceMetricSubscription.new(
            name: name,
            synthesizer: synthesizer,
            attributes: VPC::VpcNetworkPerformanceMetricSubscription::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a VPC security group egress rule for controlling outbound traffic
        #
        # @param name [Symbol] Unique name for the egress rule resource
        # @param attributes [Hash] Configuration attributes for the rule
        # @return [VPC::VpcSecurityGroupEgressRule::VpcSecurityGroupEgressRuleReference] Reference to the created rule
        def aws_vpc_security_group_egress_rule(name, attributes = {})
          resource = VPC::VpcSecurityGroupEgressRule.new(
            name: name,
            synthesizer: synthesizer,
            attributes: VPC::VpcSecurityGroupEgressRule::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a VPC security group ingress rule for controlling inbound traffic
        #
        # @param name [Symbol] Unique name for the ingress rule resource
        # @param attributes [Hash] Configuration attributes for the rule
        # @return [VPC::VpcSecurityGroupIngressRule::VpcSecurityGroupIngressRuleReference] Reference to the created rule
        def aws_vpc_security_group_ingress_rule(name, attributes = {})
          resource = VPC::VpcSecurityGroupIngressRule.new(
            name: name,
            synthesizer: synthesizer,
            attributes: VPC::VpcSecurityGroupIngressRule::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

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