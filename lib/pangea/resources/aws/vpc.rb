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
require_relative 'vpc/functions/endpoints'
require_relative 'vpc/functions/defaults'

module Pangea
  module Resources
    module AWS
      # AWS VPC Extended service module
      # Provides type-safe resource functions for advanced VPC networking, endpoints, and defaults
      module VPC
        include Endpoints
        include Defaults

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
      end
    end
  end
end
