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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS VPC Endpoint Service resources
      # Allows you to create a VPC endpoint service configuration that enables other VPCs to connect to your services
      class VpcEndpointServiceAttributes < Dry::Struct
        # Whether requests to connect to your service must be accepted (required)
        attribute :acceptance_required, Resources::Types::Bool
        
        # ARNs of one or more Network Load Balancers for the endpoint service (optional)
        attribute :network_load_balancer_arns, Resources::Types::Array.of(Types::String).default([].freeze)
        
        # ARNs of one or more Gateway Load Balancers for the endpoint service (optional)
        attribute :gateway_load_balancer_arns, Resources::Types::Array.of(Types::String).default([].freeze)
        
        # The supported IP address types (optional)
        attribute :supported_ip_address_types, Resources::Types::Array.of(
          Types::String.enum('ipv4', 'ipv6')
        ).default([].freeze)
        
        # The private DNS name for the service (optional)
        attribute :private_dns_name, Resources::Types::String.optional
        
        # The private DNS name verification state (optional)
        attribute :private_dns_name_configuration, Resources::Types::Hash.default({}.freeze)
        
        # List of principal ARNs allowed to discover the service (optional)
        attribute :allowed_principals, Resources::Types::Array.of(Types::String).default([].freeze)
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Must specify at least one type of load balancer
          if attrs.network_load_balancer_arns.empty? && attrs.gateway_load_balancer_arns.empty?
            raise Dry::Struct::Error, "Must specify either 'network_load_balancer_arns' or 'gateway_load_balancer_arns'"
          end
          
          # Cannot specify both types of load balancers
          if attrs.network_load_balancer_arns.any? && attrs.gateway_load_balancer_arns.any?
            raise Dry::Struct::Error, "Cannot specify both 'network_load_balancer_arns' and 'gateway_load_balancer_arns'"
          end
          
          # Validate ARN format for load balancers
          all_arns = attrs.network_load_balancer_arns + attrs.gateway_load_balancer_arns
          all_arns.each do |arn|
            unless arn.match?(/^arn:aws:elasticloadbalancing:/)
              raise Dry::Struct::Error, "Invalid load balancer ARN format: #{arn}"
            end
          end
          
          # Validate principal ARNs if specified
          attrs.allowed_principals.each do |principal|
            unless principal.match?(/^arn:aws:(iam::|\d+:)/)
              raise Dry::Struct::Error, "Invalid principal ARN format: #{principal}"
            end
          end
          
          # Validate private DNS name format if specified
          if attrs.private_dns_name && !attrs.private_dns_name.match?(/^[a-zA-Z0-9.-]+$/)
            raise Dry::Struct::Error, "Invalid private DNS name format: #{attrs.private_dns_name}"
          end
          
          attrs
        end

        # Check if service requires acceptance
        def requires_acceptance?
          acceptance_required
        end
        
        # Check if service uses Network Load Balancers
        def uses_network_load_balancers?
          network_load_balancer_arns.any?
        end
        
        # Check if service uses Gateway Load Balancers
        def uses_gateway_load_balancers?
          gateway_load_balancer_arns.any?
        end
        
        # Check if service has custom DNS configuration
        def has_private_dns?
          !private_dns_name.nil?
        end
        
        # Check if service has allowed principals configured
        def has_allowed_principals?
          allowed_principals.any?
        end
        
        # Get the load balancer type being used
        def load_balancer_type
          if uses_network_load_balancers?
            :network
          elsif uses_gateway_load_balancers?
            :gateway
          else
            :none
          end
        end
        
        # Get all configured load balancer ARNs
        def all_load_balancer_arns
          network_load_balancer_arns + gateway_load_balancer_arns
        end
        
        # Check if service supports IPv6
        def supports_ipv6?
          supported_ip_address_types.include?('ipv6')
        end
        
        # Check if service supports IPv4
        def supports_ipv4?
          supported_ip_address_types.empty? || supported_ip_address_types.include?('ipv4')
        end
      end
    end
      end
    end
  end
end