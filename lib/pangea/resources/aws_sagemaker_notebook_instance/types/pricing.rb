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
      module SageMakerNotebookInstance
        # Pricing calculations for SageMaker Notebook Instance
        module Pricing
          ACCELERATOR_COSTS = {
            'ml.eia1.medium' => 0.13,
            'ml.eia1.large' => 0.26,
            'ml.eia1.xlarge' => 0.52,
            'ml.eia2.medium' => 0.14,
            'ml.eia2.large' => 0.28,
            'ml.eia2.xlarge' => 0.56
          }.freeze

          T_INSTANCE_COSTS = {
            'ml.t2.medium' => 0.0464,
            'ml.t2.large' => 0.0928,
            'ml.t2.xlarge' => 0.1856,
            'ml.t2.2xlarge' => 0.3712,
            'ml.t3.medium' => 0.0548,
            'ml.t3.large' => 0.1096,
            'ml.t3.xlarge' => 0.2192,
            'ml.t3.2xlarge' => 0.4384
          }.freeze

          P_INSTANCE_COSTS = {
            'ml.p2.xlarge' => 0.9,
            'ml.p2.8xlarge' => 7.2,
            'ml.p2.16xlarge' => 14.4,
            'ml.p3.2xlarge' => 3.06,
            'ml.p3.8xlarge' => 12.24,
            'ml.p3.16xlarge' => 24.48
          }.freeze

          STORAGE_COST_PER_GB = 0.10
          HOURS_PER_MONTH = 24 * 30

          def estimated_monthly_cost
            instance_cost = get_instance_cost_per_hour * HOURS_PER_MONTH
            storage_cost = volume_size_in_gb * STORAGE_COST_PER_GB
            accelerator_cost = get_accelerator_cost_per_hour * HOURS_PER_MONTH

            instance_cost + storage_cost + accelerator_cost
          end

          def get_instance_cost_per_hour
            case instance_type
            when /^ml\.t/
              T_INSTANCE_COSTS[instance_type] || 0.1
            when /^ml\.m/
              compute_m_instance_cost
            when /^ml\.c/
              compute_c_instance_cost
            when /^ml\.r/
              compute_r_instance_cost
            when /^ml\.p/
              P_INSTANCE_COSTS[instance_type] || 1.0
            else
              0.1
            end
          end

          def get_accelerator_cost_per_hour
            return 0.0 unless accelerator_types&.any?

            accelerator_types.sum { |acc| ACCELERATOR_COSTS[acc] || 0.0 }
          end

          private

          def compute_m_instance_cost
            case instance_type
            when /xl/ then instance_type.include?('2xl') ? 0.8 : 0.4
            when /4xl/ then 1.6
            when /8xl/ then 3.2
            else 0.2
            end
          end

          def compute_c_instance_cost
            case instance_type
            when /xl/ then instance_type.include?('2xl') ? 0.6 : 0.3
            when /4xl/ then 1.2
            when /8xl/ then 2.4
            else 0.15
            end
          end

          def compute_r_instance_cost
            case instance_type
            when /xl/ then instance_type.include?('2xl') ? 1.0 : 0.5
            when /4xl/ then 2.0
            when /8xl/ then 4.0
            else 0.25
            end
          end
        end
      end
    end
  end
end
