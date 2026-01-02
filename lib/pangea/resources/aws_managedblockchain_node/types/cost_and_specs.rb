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
        # Cost and specs helper methods for ManagedBlockchainNode
        module ManagedBlockchainNodeCostAndSpecs
          HOURLY_COSTS = {
            'bc.t3.small' => 0.078,
            'bc.t3.medium' => 0.156,
            'bc.t3.large' => 0.312,
            'bc.t3.xlarge' => 0.624,
            'bc.m5.large' => 0.354,
            'bc.m5.xlarge' => 0.708,
            'bc.m5.2xlarge' => 1.416,
            'bc.m5.4xlarge' => 2.832,
            'bc.c5.large' => 0.306,
            'bc.c5.xlarge' => 0.612,
            'bc.c5.2xlarge' => 1.224,
            'bc.c5.4xlarge' => 2.448
          }.freeze

          INSTANCE_SPECS = {
            'bc.t3.small' => { vcpu: 2, memory_gib: 2, network: 'Up to 5 Gbps' },
            'bc.t3.medium' => { vcpu: 2, memory_gib: 4, network: 'Up to 5 Gbps' },
            'bc.t3.large' => { vcpu: 2, memory_gib: 8, network: 'Up to 5 Gbps' },
            'bc.t3.xlarge' => { vcpu: 4, memory_gib: 16, network: 'Up to 5 Gbps' },
            'bc.m5.large' => { vcpu: 2, memory_gib: 8, network: 'Up to 10 Gbps' },
            'bc.m5.xlarge' => { vcpu: 4, memory_gib: 16, network: 'Up to 10 Gbps' },
            'bc.m5.2xlarge' => { vcpu: 8, memory_gib: 32, network: 'Up to 10 Gbps' },
            'bc.m5.4xlarge' => { vcpu: 16, memory_gib: 64, network: 'Up to 10 Gbps' },
            'bc.c5.large' => { vcpu: 2, memory_gib: 4, network: 'Up to 10 Gbps' },
            'bc.c5.xlarge' => { vcpu: 4, memory_gib: 8, network: 'Up to 10 Gbps' },
            'bc.c5.2xlarge' => { vcpu: 8, memory_gib: 16, network: 'Up to 10 Gbps' },
            'bc.c5.4xlarge' => { vcpu: 16, memory_gib: 32, network: 'Up to 10 Gbps' }
          }.freeze

          def estimated_monthly_cost
            base_hourly = HOURLY_COSTS[node_configuration[:instance_type]] || 0

            # Add 10% for CouchDB overhead
            base_hourly *= 1.1 if uses_couchdb?

            # Add cost for CloudWatch logging
            base_hourly += 0.02 if any_logging_enabled?

            # Convert to monthly (730 hours)
            base_hourly * 730
          end

          def recommended_specs
            instance_type = node_configuration[:instance_type]
            specs = INSTANCE_SPECS[instance_type] || { vcpu: 0, memory_gib: 0, network: 'Unknown' }
            specs.merge(state_db: node_configuration[:state_db] || 'LevelDB')
          end
        end
      end
    end
  end
end
