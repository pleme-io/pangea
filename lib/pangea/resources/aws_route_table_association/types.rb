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
        # Type-safe attributes for AWS Route Table Association resources
        # Associates a route table with either a subnet or internet/vpn gateway
        class RouteTableAssociationAttributes < Dry::Struct
          # Required: The ID of the routing table to associate
          attribute :route_table_id, Resources::Types::String
          
          # Optional: The subnet ID to associate (mutually exclusive with gateway_id)
          attribute? :subnet_id, Resources::Types::String.optional
          
          # Optional: The gateway ID to associate for edge associations (mutually exclusive with subnet_id)
          attribute? :gateway_id, Resources::Types::String.optional
          
          # Note: Route table associations don't support tags in AWS

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            
            # Must specify either subnet_id or gateway_id, but not both
            if attrs.subnet_id.nil? && attrs.gateway_id.nil?
              raise Dry::Struct::Error, "Must specify either 'subnet_id' or 'gateway_id'"
            end
            
            if attrs.subnet_id && attrs.gateway_id
              raise Dry::Struct::Error, "Cannot specify both 'subnet_id' and 'gateway_id' - they are mutually exclusive"
            end
            
            attrs
          end
          
          # Determine association type
          def association_type
            if subnet_id
              :subnet
            elsif gateway_id
              :gateway
            else
              :unknown
            end
          end
          
          # Get the target ID (subnet or gateway)
          def target_id
            subnet_id || gateway_id
          end
          
          # Check if this is a subnet association
          def subnet_association?
            !subnet_id.nil?
          end
          
          # Check if this is a gateway association
          def gateway_association?
            !gateway_id.nil?
          end
          
          # Human-readable target type
          def target_type
            case association_type
            when :subnet
              "Subnet"
            when :gateway
              "Gateway (Internet/VPN)"
            else
              "Unknown"
            end
          end
        end
      end
    end
  end
end