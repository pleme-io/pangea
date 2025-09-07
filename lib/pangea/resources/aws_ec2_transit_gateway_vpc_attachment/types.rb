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
        # Transit Gateway VPC Attachment resource attributes with validation
        class TransitGatewayVpcAttachmentAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :transit_gateway_id, Resources::Types::String
          attribute :vpc_id, Resources::Types::String
          attribute :subnet_ids, Resources::Types::Array.of(Resources::Types::String).constrained(min_size: 1)
          attribute? :appliance_mode_support, Resources::Types::TransitGatewayVpcAttachmentApplianceModeSupport
          attribute? :dns_support, Resources::Types::TransitGatewayVpcAttachmentDnsSupport
          attribute? :ipv6_support, Resources::Types::TransitGatewayVpcAttachmentIpv6Support
          attribute? :transit_gateway_default_route_table_association, Resources::Types::Bool.optional
          attribute? :transit_gateway_default_route_table_propagation, Resources::Types::Bool.optional
          attribute? :tags, Resources::Types::AwsTags
          
          # Custom validation for VPC attachment configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate subnet IDs format (basic validation)
            if attrs[:subnet_ids]
              attrs[:subnet_ids].each do |subnet_id|
                unless subnet_id.match?(/\Asubnet-[0-9a-f]{8,17}\z/)
                  raise Dry::Struct::Error, "Invalid subnet ID format: #{subnet_id}. Expected format: subnet-xxxxxxxx"
                end
              end
            end
            
            # Validate VPC ID format
            if attrs[:vpc_id] && !attrs[:vpc_id].match?(/\Avpc-[0-9a-f]{8,17}\z/)
              raise Dry::Struct::Error, "Invalid VPC ID format: #{attrs[:vpc_id]}. Expected format: vpc-xxxxxxxx"
            end
            
            # Validate Transit Gateway ID format
            if attrs[:transit_gateway_id] && !attrs[:transit_gateway_id].match?(/\Atgw-[0-9a-f]{8,17}\z/)
              raise Dry::Struct::Error, "Invalid Transit Gateway ID format: #{attrs[:transit_gateway_id]}. Expected format: tgw-xxxxxxxx"
            end
            
            # Validate subnet count for high availability
            if attrs[:subnet_ids] && attrs[:subnet_ids].length == 1
              # Single subnet attachment - warn about availability
              # This is allowed but not recommended for production
            end
            
            super(attrs)
          end
          
          # Computed properties
          def is_highly_available?
            # Multiple subnets provide high availability
            subnet_ids.length > 1
          end
          
          def supports_appliance_mode_inspection?
            appliance_mode_support == 'enable'
          end
          
          def estimated_monthly_cost
            # VPC attachment cost: $36.50 per month per attachment
            base_cost = 36.50
            
            {
              monthly_attachment_cost: base_cost,
              currency: 'USD',
              note: 'Fixed monthly cost per VPC attachment. Data processing charges apply separately.'
            }
          end
          
          def availability_zones_count
            # Estimate AZ count based on subnet count (assuming best practice deployment)
            case subnet_ids.length
            when 1 then 1
            when 2 then 2
            when 3 then 3
            else subnet_ids.length # Could be more than 3 AZs
            end
          end
          
          def security_considerations
            considerations = []
            
            unless is_highly_available?
              considerations << "Single subnet attachment - no high availability. Consider adding subnets in additional AZs"
            end
            
            if appliance_mode_support == 'enable'
              considerations << "Appliance mode support is enabled - traffic will be directed to a single network appliance"
            end
            
            if dns_support == 'disable'
              considerations << "DNS support is disabled - DNS resolution across the Transit Gateway will not work"
            end
            
            if transit_gateway_default_route_table_association == false
              considerations << "Default route table association is disabled - ensure custom route table is associated"
            end
            
            if transit_gateway_default_route_table_propagation == false
              considerations << "Default route table propagation is disabled - routes will not be automatically propagated"
            end
            
            considerations
          end
          
          def routing_behavior
            behavior = {
              default_route_table_association: transit_gateway_default_route_table_association,
              default_route_table_propagation: transit_gateway_default_route_table_propagation,
              dns_resolution: dns_support == 'enable',
              appliance_mode: appliance_mode_support == 'enable'
            }
            
            # Determine routing pattern
            if transit_gateway_default_route_table_association && transit_gateway_default_route_table_propagation
              behavior[:pattern] = 'full_mesh'
            elsif transit_gateway_default_route_table_association && !transit_gateway_default_route_table_propagation
              behavior[:pattern] = 'hub_and_spoke_receiver'
            elsif !transit_gateway_default_route_table_association && transit_gateway_default_route_table_propagation
              behavior[:pattern] = 'hub_and_spoke_sender'
            else
              behavior[:pattern] = 'isolated'
            end
            
            behavior
          end
        end
      end
    end
  end
end