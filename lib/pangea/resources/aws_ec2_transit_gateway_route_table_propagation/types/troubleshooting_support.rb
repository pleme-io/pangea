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
        # Troubleshooting and route advertisement support for Transit Gateway Route Table Propagation
        module TroubleshootingSupport
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

          def troubleshooting_guide
            {
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
          end
        end
      end
    end
  end
end
