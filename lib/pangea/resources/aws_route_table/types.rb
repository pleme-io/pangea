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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Route attributes for route table
        class RouteAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Destination CIDR block for the route
          attribute :cidr_block, Resources::Types::CidrBlock.optional.default(nil)
          attribute :ipv6_cidr_block, Resources::Types::String.optional.default(nil)
          
          # Route targets (only one should be specified)
          attribute :gateway_id, Resources::Types::String.optional.default(nil)
          attribute :nat_gateway_id, Resources::Types::String.optional.default(nil)
          attribute :network_interface_id, Resources::Types::String.optional.default(nil)
          attribute :transit_gateway_id, Resources::Types::String.optional.default(nil)
          attribute :vpc_peering_connection_id, Resources::Types::String.optional.default(nil)
          attribute :vpc_endpoint_id, Resources::Types::String.optional.default(nil)
          attribute :egress_only_gateway_id, Resources::Types::String.optional.default(nil)
          
          # Validate that at least one destination and one target are specified
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Check for at least one destination
            destinations = [:cidr_block, :ipv6_cidr_block]
            has_destination = destinations.any? { |d| attrs[d] }
            
            unless has_destination
              raise Dry::Struct::Error, "Route must have either cidr_block or ipv6_cidr_block"
            end
            
            # Check for exactly one target
            targets = [:gateway_id, :nat_gateway_id, :network_interface_id, 
                      :transit_gateway_id, :vpc_peering_connection_id, 
                      :vpc_endpoint_id, :egress_only_gateway_id]
            
            specified_targets = targets.select { |t| attrs[t] }
            
            if specified_targets.empty?
              raise Dry::Struct::Error, "Route must specify exactly one target (gateway_id, nat_gateway_id, etc.)"
            elsif specified_targets.size > 1
              raise Dry::Struct::Error, "Route can only have one target, but multiple were specified: #{specified_targets.join(', ')}"
            end
            
            super(attrs)
          end
          
          def to_h
            # Only include non-nil attributes
            attributes.reject { |_, v| v.nil? }
          end
        end
        
        # Route Table resource attributes with validation
        class RouteTableAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :vpc_id, Resources::Types::String
          attribute :routes, Resources::Types::Array.of(RouteAttributes).default([].freeze)
          attribute :tags, Resources::Types::AwsTags
          
          # Computed properties
          def route_count
            routes.size
          end
          
          def has_internet_route?
            routes.any? { |r| r.cidr_block == "0.0.0.0/0" && r.gateway_id }
          end
          
          def has_nat_route?
            routes.any? { |r| r.nat_gateway_id }
          end
          
          def to_h
            {
              vpc_id: vpc_id,
              routes: routes.map(&:to_h),
              tags: tags
            }
          end
        end
      end
    end
  end
end