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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_vpc_endpoint_service/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create a VPC Endpoint Service with type-safe attributes
      #
      # VPC endpoint services allow you to expose your own application services to other VPCs
      # through AWS PrivateLink, enabling secure, private connectivity without internet routing.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @option attributes [Boolean] :acceptance_required Whether requests must be accepted
      # @option attributes [Array<String>] :network_load_balancer_arns NLB ARNs for the service
      # @option attributes [Array<String>] :gateway_load_balancer_arns GWLB ARNs for the service
      # @option attributes [Array<String>] :supported_ip_address_types Supported IP types
      # @option attributes [String] :private_dns_name Private DNS name for the service
      # @option attributes [Hash] :private_dns_name_configuration DNS configuration
      # @option attributes [Array<String>] :allowed_principals Allowed principal ARNs
      # @option attributes [Hash] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_vpc_endpoint_service(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::VpcEndpointServiceAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_vpc_endpoint_service, name) do
          # Required: Whether requests to connect must be accepted
          acceptance_required attrs.acceptance_required
          
          # Load balancer ARNs (one type required)
          if attrs.network_load_balancer_arns.any?
            network_load_balancer_arns attrs.network_load_balancer_arns
          end
          
          if attrs.gateway_load_balancer_arns.any?
            gateway_load_balancer_arns attrs.gateway_load_balancer_arns
          end
          
          # Optional: Supported IP address types
          if attrs.supported_ip_address_types.any?
            supported_ip_address_types attrs.supported_ip_address_types
          end
          
          # Optional: Private DNS name
          if attrs.private_dns_name
            private_dns_name attrs.private_dns_name
          end
          
          # Optional: Private DNS name configuration
          if attrs.private_dns_name_configuration.any?
            private_dns_name_configuration do
              attrs.private_dns_name_configuration.each do |key, value|
                public_send(key, value)
              end
            end
          end
          
          # Optional: Allowed principals
          if attrs.allowed_principals.any?
            allowed_principals attrs.allowed_principals
          end
          
          # Apply tags if present
          if attrs.tags.any?
            tags do
              attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_vpc_endpoint_service',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_vpc_endpoint_service.#{name}.id}",
            arn: "${aws_vpc_endpoint_service.#{name}.arn}",
            service_name: "${aws_vpc_endpoint_service.#{name}.service_name}",
            service_type: "${aws_vpc_endpoint_service.#{name}.service_type}",
            state: "${aws_vpc_endpoint_service.#{name}.state}",
            availability_zones: "${aws_vpc_endpoint_service.#{name}.availability_zones}",
            base_endpoint_dns_names: "${aws_vpc_endpoint_service.#{name}.base_endpoint_dns_names}",
            manages_vpc_endpoints: "${aws_vpc_endpoint_service.#{name}.manages_vpc_endpoints}",
            private_dns_name_configuration: "${aws_vpc_endpoint_service.#{name}.private_dns_name_configuration}"
          },
          computed_properties: {
            requires_acceptance: attrs.requires_acceptance?,
            uses_network_load_balancers: attrs.uses_network_load_balancers?,
            uses_gateway_load_balancers: attrs.uses_gateway_load_balancers?,
            has_private_dns: attrs.has_private_dns?,
            has_allowed_principals: attrs.has_allowed_principals?,
            load_balancer_type: attrs.load_balancer_type,
            supports_ipv6: attrs.supports_ipv6?,
            supports_ipv4: attrs.supports_ipv4?
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)