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
        # Security considerations and impact assessment for Transit Gateway Route Table Propagation
        module SecurityConcerns
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

          def estimated_impact
            impact = {
              scope: "route_table_route_population",
              automation_level: "high",
              change_frequency: "dynamic",
              reversibility: "easy",
              monitoring_requirements: "medium"
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
