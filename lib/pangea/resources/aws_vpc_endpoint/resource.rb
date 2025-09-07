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
require 'pangea/resources/aws_vpc_endpoint/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AwsVpcEndpoint
      # Create an AWS VPC Endpoint with type-safe attributes
      #
      # VPC endpoints enable private connectivity to AWS services without requiring
      # an internet gateway, NAT instance, or NAT gateway.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_vpc_endpoint(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::VpcEndpointAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_vpc_endpoint, name) do
          # Required attributes
          vpc_id attrs.vpc_id
          service_name attrs.service_name
          
          # VPC endpoint type (Gateway or Interface)
          vpc_endpoint_type attrs.vpc_endpoint_type
          
          # Route table IDs for Gateway endpoints
          if attrs.route_table_ids && !attrs.route_table_ids.empty?
            route_table_ids attrs.route_table_ids
          end
          
          # Subnet IDs for Interface endpoints
          if attrs.subnet_ids && !attrs.subnet_ids.empty?
            subnet_ids attrs.subnet_ids
          end
          
          # Security group IDs for Interface endpoints
          if attrs.security_group_ids && !attrs.security_group_ids.empty?
            security_group_ids attrs.security_group_ids
          end
          
          # Policy document
          if attrs.policy
            policy attrs.policy
          end
          
          # Private DNS enabled (Interface endpoints only)
          if attrs.interface_endpoint?
            private_dns_enabled attrs.private_dns_enabled
          end
          
          # Auto accept endpoint connections
          auto_accept attrs.auto_accept
          
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
        Pangea::Resources::ResourceReference.new(
          type: 'aws_vpc_endpoint',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_vpc_endpoint.#{name}.id}",
            arn: "${aws_vpc_endpoint.#{name}.arn}",
            cidr_blocks: "${aws_vpc_endpoint.#{name}.cidr_blocks}",
            creation_timestamp: "${aws_vpc_endpoint.#{name}.creation_timestamp}",
            dns_entry: "${aws_vpc_endpoint.#{name}.dns_entry}",
            network_interface_ids: "${aws_vpc_endpoint.#{name}.network_interface_ids}",
            owner_id: "${aws_vpc_endpoint.#{name}.owner_id}",
            policy: "${aws_vpc_endpoint.#{name}.policy}",
            prefix_list_id: "${aws_vpc_endpoint.#{name}.prefix_list_id}",
            private_dns_enabled: "${aws_vpc_endpoint.#{name}.private_dns_enabled}",
            requester_managed: "${aws_vpc_endpoint.#{name}.requester_managed}",
            route_table_ids: "${aws_vpc_endpoint.#{name}.route_table_ids}",
            security_group_ids: "${aws_vpc_endpoint.#{name}.security_group_ids}",
            service_name: "${aws_vpc_endpoint.#{name}.service_name}",
            state: "${aws_vpc_endpoint.#{name}.state}",
            subnet_ids: "${aws_vpc_endpoint.#{name}.subnet_ids}",
            tags_all: "${aws_vpc_endpoint.#{name}.tags_all}",
            vpc_endpoint_type: "${aws_vpc_endpoint.#{name}.vpc_endpoint_type}",
            vpc_id: "${aws_vpc_endpoint.#{name}.vpc_id}"
          },
          computed_properties: {
            gateway_endpoint: attrs.gateway_endpoint?,
            interface_endpoint: attrs.interface_endpoint?,
            aws_service: attrs.aws_service,
            aws_region: attrs.aws_region,
            has_policy: attrs.has_policy?,
            connectivity_type: attrs.connectivity_type
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)