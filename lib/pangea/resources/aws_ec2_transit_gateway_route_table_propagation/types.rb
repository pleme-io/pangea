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
        # Transit Gateway Route Table Propagation resource attributes with validation
        class TransitGatewayRouteTablePropagationAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :transit_gateway_attachment_id, Resources::Types::String
          attribute :transit_gateway_route_table_id, Resources::Types::String
          
          # Custom validation for propagation configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate attachment ID format
            if attrs[:transit_gateway_attachment_id] && !attrs[:transit_gateway_attachment_id].match?(/\Atgw-attach-[0-9a-f]{8,17}\z/)
              raise Dry::Struct::Error, "Invalid Transit Gateway Attachment ID format: #{attrs[:transit_gateway_attachment_id]}. Expected format: tgw-attach-xxxxxxxx"
            end
            
            # Validate route table ID format
            if attrs[:transit_gateway_route_table_id] && !attrs[:transit_gateway_route_table_id].match?(/\Atgw-rtb-[0-9a-f]{8,17}\z/)
              raise Dry::Struct::Error, "Invalid Transit Gateway Route Table ID format: #{attrs[:transit_gateway_route_table_id]}. Expected format: tgw-rtb-xxxxxxxx"
            end
            
            super(attrs)
          end
          
          # Computed properties
          def propagation_purpose
            "Propagates routes from attachment #{transit_gateway_attachment_id} to route table #{transit_gateway_route_table_id}"
          end
          
          def route_advertisement_behavior
            {
              direction: "inbound_to_route_table",
              mechanism: "automatic_route_propagation", 
              route_type: "propagated_routes",
              override_capability: "static_routes_override_propagated"
            }
          end
          
          def propagation_implications
            implications = {
              route_creation: "Routes from the attachment will be automatically created in the route table",
              route_management: "Propagated routes are managed automatically - do not create static routes for same CIDRs",
              route_priority: "Static routes take precedence over propagated routes for the same destination",
              dynamic_updates: "Route changes in source attachment are automatically reflected in route table"
            }
            
            implications[:traffic_flow] = "Other attachments associated with this route table will learn routes to the propagating attachment"
            implications[:bidirectional_note] = "Propagation only advertises routes TO the attachment, not FROM it"
            
            implications
          end
          
          def security_considerations
            considerations = []
            
            considerations << "Route propagation automatically advertises attachment's routes to the route table"
            considerations << "All attachments associated with the route table will learn propagated routes"
            considerations << "Propagated routes can be overridden by static routes for security policies"
            considerations << "Route propagation enables dynamic connectivity that may bypass static security controls"
            
            considerations << "Consider whether automatic route propagation aligns with security segmentation requirements"
            considerations << "Monitor propagated routes to ensure they don't create unintended connectivity paths"
            considerations << "Document which attachments propagate to which route tables for security reviews"
            
            considerations
          end
          
          def operational_insights
            insights = {
              automation_level: "fully_automatic",
              route_lifecycle: "managed_by_aws",
              troubleshooting_complexity: "medium", # Propagated routes can be confusing
              change_detection: "cloudtrail_and_route_monitoring"
            }
            
            insights[:best_practices] = [
              "Use route propagation for dynamic environments where routes change frequently",
              "Combine with static routes for fine-grained control over specific destinations",
              "Document propagation relationships for operational clarity",
              "Monitor route table size to avoid hitting AWS limits"
            ]
            
            insights[:when_to_use] = [
              "VPC attachments with changing subnets",
              "VPN connections with dynamic routing",
              "Direct Connect gateways with BGP",
              "Peering connections between dynamic environments"
            ]
            
            insights[:when_not_to_use] = [
              "High-security environments requiring manual route control",
              "Static environments where routes never change",
              "Situations requiring asymmetric routing policies"
            ]
            
            insights
          end
          
          def route_propagation_scenarios
            scenarios = {
              vpc_attachment: {
                description: "VPC subnets are propagated as routes",
                route_source: "VPC CIDR and associated subnets",
                update_trigger: "Subnet creation/deletion in VPC",
                typical_use_case: "Dynamic subnet management"
              },
              vpn_attachment: {
                description: "Customer network routes learned via BGP",
                route_source: "BGP advertisements from customer gateway",
                update_trigger: "BGP route updates from on-premises",
                typical_use_case: "Dynamic on-premises connectivity"
              },
              dx_gateway_attachment: {
                description: "Direct Connect virtual interface routes",
                route_source: "BGP advertisements from Direct Connect",
                update_trigger: "BGP updates from Direct Connect partner",
                typical_use_case: "Enterprise network integration"
              },
              peering_attachment: {
                description: "Routes from peered Transit Gateway",
                route_source: "Routes from remote Transit Gateway",
                update_trigger: "Route changes in remote Transit Gateway",
                typical_use_case: "Cross-region or cross-account connectivity"
              }
            }
            
            scenarios
          end
          
          def troubleshooting_guide
            guide = {
              common_issues: [
                "Propagated routes not appearing: Check attachment state and route table association",
                "Route conflicts: Static routes override propagated routes for same destination",
                "Unexpected connectivity: Propagated routes may create paths not anticipated",
                "Route limits exceeded: Monitor route table size, AWS limits at 10,000 routes per table"
              ],
              verification_steps: [
                "Verify attachment is in 'available' state",
                "Check that source attachment has routes to propagate",
                "Confirm route table association exists for destination attachments", 
                "Validate no static routes conflict with propagated routes"
              ],
              monitoring_approaches: [
                "Use CloudWatch metrics for route table route count",
                "Monitor Transit Gateway route table via AWS Console",
                "Track propagation changes through CloudTrail events",
                "Use VPC Flow Logs to verify traffic follows propagated routes"
              ],
              debugging_techniques: [
                "Compare route table contents before/after propagation",
                "Use traceroute to verify traffic path through propagated routes",
                "Check BGP status for VPN/Direct Connect attachments",
                "Validate attachment association and propagation configuration"
              ]
            }
            
            guide
          end
          
          def estimated_impact
            impact = {
              scope: "route_table_route_population",
              automation_level: "high",
              change_frequency: "dynamic", # Routes update automatically
              reversibility: "easy", # Can disable propagation
              monitoring_requirements: "medium" # Need to watch for unexpected routes
            }
            
            impact[:benefits] = [
              "Automatic route management reduces operational overhead",
              "Dynamic environments stay connected as routes change",
              "BGP integration enables enterprise-grade networking",
              "Reduces risk of manual route configuration errors"
            ]
            
            impact[:risks] = [
              "Automatic routes may create unintended connectivity",
              "Route limits can be reached more quickly with propagation",
              "Troubleshooting is more complex with dynamic routes",
              "Security policies may be bypassed by propagated routes"
            ]
            
            impact
          end
        end
      end
    end
  end
end