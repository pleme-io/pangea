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
    module AwsVpcEndpoint
      module Types
        # Type-safe attributes for AWS VPC Endpoint resources
        class VpcEndpointAttributes < Dry::Struct
          transform_keys(&:to_sym)
          # Required attributes
          attribute :vpc_id, Resources::Types::String
          attribute :service_name, Resources::Types::String
        
          # VPC Endpoint type ("Gateway" or "Interface")
          attribute :vpc_endpoint_type, Resources::Types::String.default("Gateway").constrained(included_in: ["Gateway", "Interface"])
        
          # Route table IDs for Gateway endpoints
          attribute? :route_table_ids, Resources::Types::Array.of(Resources::Types::String).optional
        
          # Subnet IDs for Interface endpoints
          attribute? :subnet_ids, Resources::Types::Array.of(Resources::Types::String).optional
        
          # Security group IDs for Interface endpoints
          attribute? :security_group_ids, Resources::Types::Array.of(Resources::Types::String).optional
        
          # Policy document (JSON string)
          attribute? :policy, Resources::Types::String.optional
        
          # Enable private DNS for Interface endpoints
          attribute? :private_dns_enabled, Resources::Types::Bool.default(true)
        
          # Auto accept endpoint connections
          attribute? :auto_accept, Resources::Types::Bool.default(false)
        
          # Tags to apply to the resource
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate Interface endpoint requirements
          if attrs.vpc_endpoint_type == "Interface"
            if attrs.subnet_ids.nil? || attrs.subnet_ids.empty?
              raise Dry::Struct::Error, "Interface endpoints require 'subnet_ids' to be specified"
            end
            
            if attrs.route_table_ids && !attrs.route_table_ids.empty?
              raise Dry::Struct::Error, "Interface endpoints cannot use 'route_table_ids' (use 'subnet_ids' instead)"
            end
          end
          
          # Validate Gateway endpoint requirements
          if attrs.vpc_endpoint_type == "Gateway"
            if attrs.subnet_ids && !attrs.subnet_ids.empty?
              raise Dry::Struct::Error, "Gateway endpoints cannot use 'subnet_ids' (use 'route_table_ids' instead)"
            end
            
            if attrs.security_group_ids && !attrs.security_group_ids.empty?
              raise Dry::Struct::Error, "Gateway endpoints do not support 'security_group_ids'"
            end
            
            if attrs.private_dns_enabled != true
              raise Dry::Struct::Error, "Gateway endpoints do not support 'private_dns_enabled' (only Interface endpoints)"
            end
          end
          
          # Validate service name format
          unless attrs.service_name.match?(/\Acom\.amazonaws\.[a-z0-9-]+\.[a-z0-9-]+\z/)
            raise Dry::Struct::Error, "Invalid 'service_name' format. Expected: com.amazonaws.region.service"
          end
          
          attrs
        end

          # Check if this is a Gateway endpoint
          def gateway_endpoint?
          vpc_endpoint_type == "Gateway"
        end
        
          # Check if this is an Interface endpoint
          def interface_endpoint?
          vpc_endpoint_type == "Interface"
        end
        
          # Extract AWS service name from service_name
          def aws_service
          service_name.split('.').last
        end
        
          # Extract AWS region from service_name
          def aws_region
          parts = service_name.split('.')
          return nil unless parts.length >= 4
          parts[2]
        end
        
          # Check if endpoint has policy attached
          def has_policy?
          !policy.nil? && !policy.empty?
        end
        
          # Get the endpoint connectivity type
          def connectivity_type
          case vpc_endpoint_type
          when "Gateway"
            :gateway
          when "Interface"
            :interface
          end
        end
        end
      end
    end
  end
end
