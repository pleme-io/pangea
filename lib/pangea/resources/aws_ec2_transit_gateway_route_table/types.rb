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
        # Transit Gateway Route Table resource attributes with validation
        class TransitGatewayRouteTableAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :transit_gateway_id, Resources::Types::String
          attribute? :tags, Resources::Types::AwsTags
          
          # Custom validation for route table configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate Transit Gateway ID format
            if attrs[:transit_gateway_id] && !attrs[:transit_gateway_id].match?(/\Atgw-[0-9a-f]{8,17}\z/)
              raise Dry::Struct::Error, "Invalid Transit Gateway ID format: #{attrs[:transit_gateway_id]}. Expected format: tgw-xxxxxxxx"
            end
            
            super(attrs)
          end
          
          # Computed properties
          def supports_route_propagation?
            # All custom route tables support route propagation
            true
          end
          
          def supports_route_association?
            # All route tables support attachment association
            true
          end
          
          def estimated_monthly_cost
            # Route tables themselves don't have additional costs
            # Cost is included in the Transit Gateway base cost
            {
              monthly_cost: 0.0,
              currency: 'USD',
              note: 'Route tables are included in Transit Gateway base cost. No additional charges.'
            }
          end
          
          def route_table_purpose_analysis
            # Analyze common route table naming patterns to infer purpose
            tags_hash = tags.is_a?(Hash) ? tags : {}
            name = tags_hash[:Name] || tags_hash[:name] || ''
            
            purposes = []
            
            case name.downcase
            when /prod|production/
              purposes << 'production_workloads'
            when /dev|development/
              purposes << 'development_workloads'
            when /test|staging/
              purposes << 'testing_workloads'
            when /shared|common/
              purposes << 'shared_services'
            when /security|firewall|inspection/
              purposes << 'security_inspection'
            when /egress|internet/
              purposes << 'internet_egress'
            when /hub/
              purposes << 'hub_connectivity'
            when /spoke/
              purposes << 'spoke_connectivity'
            when /isolated|private/
              purposes << 'network_isolation'
            end
            
            # Additional analysis based on other tags
            if tags_hash[:Environment]
              purposes << "#{tags_hash[:Environment].downcase}_environment"
            end
            
            if tags_hash[:Segment] || tags_hash[:segment]
              segment = (tags_hash[:Segment] || tags_hash[:segment]).downcase
              purposes << "#{segment}_segment"
            end
            
            purposes.empty? ? ['general_purpose'] : purposes
          end
          
          def security_considerations
            considerations = []
            
            # Route tables provide network segmentation
            considerations << "Custom route tables enable network segmentation and traffic isolation"
            considerations << "Routes must be explicitly defined - no default connectivity"
            considerations << "Association and propagation must be configured for each attachment"
            
            # Analyze tags for security context
            if tags[:Environment] == 'production' || tags[:environment] == 'production'
              considerations << "Production route table - ensure strict route policies and monitoring"
            end
            
            if route_table_purpose_analysis.include?('security_inspection')
              considerations << "Security inspection route table - ensure all traffic flows through security appliances"
            end
            
            considerations
          end
          
          def routing_capabilities
            {
              supports_static_routes: true,
              supports_propagated_routes: true,
              supports_blackhole_routes: true,
              supports_cross_account_attachments: true,
              supports_vpn_attachments: true,
              supports_dx_gateway_attachments: true,
              supports_peering_attachments: true,
              max_routes_per_table: 10000 # AWS limit
            }
          end
          
          def best_practices
            practices = [
              "Use descriptive names and tags for route table identification",
              "Implement least-privilege routing - only allow necessary routes", 
              "Monitor route table utilization and route count",
              "Document route table purpose and associated attachments",
              "Use consistent naming conventions across route tables"
            ]
            
            # Add context-specific practices
            purposes = route_table_purpose_analysis
            
            if purposes.include?('production_workloads')
              practices << "Production route table - implement change management processes"
              practices << "Enable detailed monitoring and alerting for route changes"
            end
            
            if purposes.include?('security_inspection')
              practices << "Security route table - ensure redundant paths for high availability"
              practices << "Regularly audit routes to security appliances"
            end
            
            if purposes.include?('shared_services')
              practices << "Shared services route table - document all consuming applications"
              practices << "Implement service-level routing policies"
            end
            
            practices
          end
        end
      end
    end
  end
end