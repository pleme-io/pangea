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
        # Type-safe attributes for AwsRoute resources
        # Provides a resource to create a routing table entry (a route) in a VPC routing table.
        class StandaloneRouteAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :route_table_id, Resources::Types::String
          attribute? :destination_cidr_block, Resources::Types::String.optional
          attribute? :destination_ipv6_cidr_block, Resources::Types::String.optional
          attribute? :destination_prefix_list_id, Resources::Types::String.optional
          attribute? :carrier_gateway_id, Resources::Types::String.optional
          attribute? :core_network_arn, Resources::Types::String.optional
          attribute? :egress_only_gateway_id, Resources::Types::String.optional
          attribute? :gateway_id, Resources::Types::String.optional
          attribute? :nat_gateway_id, Resources::Types::String.optional
          attribute? :local_gateway_id, Resources::Types::String.optional
          attribute? :network_interface_id, Resources::Types::String.optional
          attribute? :transit_gateway_id, Resources::Types::String.optional
          attribute? :vpc_endpoint_id, Resources::Types::String.optional
          attribute? :vpc_peering_connection_id, Resources::Types::String.optional
          
          # Tags to apply to the resource
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            
            # One of destination_cidr_block, destination_ipv6_cidr_block or destination_prefix_list_id must be specified
            # Only one target can be specified (gateway_id, nat_gateway_id, instance_id, etc.)
            # Must specify one destination
            destinations = [attrs.destination_cidr_block, attrs.destination_ipv6_cidr_block, attrs.destination_prefix_list_id].compact
            if destinations.empty?
              raise Dry::Struct::Error, "One of 'destination_cidr_block', 'destination_ipv6_cidr_block', or 'destination_prefix_list_id' must be specified"
            end
            if destinations.size > 1
              raise Dry::Struct::Error, "Only one destination can be specified"
            end

            # Must specify exactly one target
            targets = [
              attrs.carrier_gateway_id, attrs.core_network_arn, attrs.egress_only_gateway_id,
              attrs.gateway_id, attrs.nat_gateway_id, attrs.local_gateway_id,
              attrs.network_interface_id, attrs.transit_gateway_id, attrs.vpc_endpoint_id,
              attrs.vpc_peering_connection_id
            ].compact

            if targets.empty?
              raise Dry::Struct::Error, "Must specify one target (gateway_id, nat_gateway_id, etc.)"
            end
            if targets.size > 1
              raise Dry::Struct::Error, "Only one target can be specified"
            end
            
            attrs
          end
          
          # Determine destination type
          def destination_type
            if destination_cidr_block
              :ipv4
            elsif destination_ipv6_cidr_block
              :ipv6
            elsif destination_prefix_list_id
              :prefix_list
            else
              :unknown
            end
          end

          # Determine target type
          def target_type
            if gateway_id
              :internet_gateway
            elsif nat_gateway_id
              :nat_gateway
            elsif network_interface_id
              :network_interface
            elsif transit_gateway_id
              :transit_gateway
            elsif vpc_peering_connection_id
              :vpc_peering
            elsif vpc_endpoint_id
              :vpc_endpoint
            elsif egress_only_gateway_id
              :egress_only_gateway
            elsif local_gateway_id
              :local_gateway
            elsif carrier_gateway_id
              :carrier_gateway
            elsif core_network_arn
              :core_network
            else
              :unknown
            end
          end
        end
      end
    end
  end
end