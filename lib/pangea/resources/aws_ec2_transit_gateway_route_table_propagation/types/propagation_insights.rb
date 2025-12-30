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

module Pangea
  module Resources
    module AWS
      module Types
        # Propagation insights and scenario methods for Transit Gateway Route Table Propagation
        module PropagationInsights
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

          def operational_insights
            insights = {
              automation_level: "fully_automatic",
              route_lifecycle: "managed_by_aws",
              troubleshooting_complexity: "medium",
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
            {
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
          end
        end
      end
    end
  end
end
