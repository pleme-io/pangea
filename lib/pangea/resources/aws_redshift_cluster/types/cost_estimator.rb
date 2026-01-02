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
        # Cost estimation methods for Redshift clusters
        module RedshiftCostEstimator
          # Hourly rates per node type (USD)
          HOURLY_RATES = {
            'dc2.large' => 0.25,
            'dc2.8xlarge' => 4.80,
            'ra3.xlplus' => 1.086,
            'ra3.4xlarge' => 3.26,
            'ra3.16xlarge' => 13.04
          }.freeze

          HOURS_PER_MONTH = 730
          RA3_STORAGE_PER_NODE_GB = 1024
          MANAGED_STORAGE_COST_PER_GB = 0.024
          S3_STANDARD_COST_PER_GB = 0.023
          SNAPSHOT_SIZE_FACTOR = 0.1

          # Estimate monthly cost
          def estimated_monthly_cost_usd
            compute_cost + storage_cost + snapshot_cost
          end

          private

          def compute_cost
            hourly_rate = HOURLY_RATES[node_type] || 0
            hourly_rate * number_of_nodes * HOURS_PER_MONTH
          end

          def storage_cost
            return 0 unless uses_ra3_nodes?

            number_of_nodes * RA3_STORAGE_PER_NODE_GB * MANAGED_STORAGE_COST_PER_GB
          end

          def snapshot_cost
            return 0 unless automated_snapshot_retention_period.positive?

            snapshot_gb = (total_storage_capacity_gb || RA3_STORAGE_PER_NODE_GB) * SNAPSHOT_SIZE_FACTOR
            snapshot_gb * S3_STANDARD_COST_PER_GB
          end
        end
      end
    end
  end
end
