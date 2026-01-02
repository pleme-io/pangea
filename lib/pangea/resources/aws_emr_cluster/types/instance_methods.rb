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
        module EmrClusterInstanceMethods
          def uses_spark?
            applications.include?('Spark')
          end

          def uses_hive?
            applications.include?('Hive')
          end

          def uses_presto?
            applications.include?('Presto') || applications.include?('Trino')
          end

          def uses_ml_frameworks?
            (applications & %w[MXNet TensorFlow]).any?
          end

          def uses_notebooks?
            (applications & %w[JupyterHub Zeppelin]).any?
          end

          def is_multi_az?
            ec2_attributes[:subnet_ids]&.size.to_i > 1
          end

          def uses_spot_instances?
            return true if core_instance_group&.dig(:bid_price)
            task_instance_groups.any? { |group| group[:bid_price] }
          end

          def has_auto_scaling?
            task_instance_groups.any? { |group| group[:auto_scaling_policy] }
          end

          def total_core_instances
            core_instance_group&.dig(:instance_count) || 0
          end

          def total_task_instances
            task_instance_groups.sum { |group| group[:instance_count] }
          end

          def total_cluster_instances
            1 + total_core_instances + total_task_instances
          end

          def estimated_hourly_cost_usd
            base_costs = instance_cost_map
            total = calculate_master_cost(base_costs) + calculate_core_cost(base_costs) + calculate_task_cost(base_costs)
            total *= 0.3 if uses_spot_instances?
            total.round(4)
          end

          def configuration_warnings
            warnings = []
            warnings << 'Very large cluster (>1000 instances) may face resource limits' if total_cluster_instances > 1000
            warnings << 'Consider adding Spark for better performance on most workloads' unless uses_spark?
            warnings << 'Consider enabling cluster logging for troubleshooting' unless log_uri
            warnings << 'Consider enabling termination protection for production clusters' if !termination_protection && !uses_spot_instances?
            warnings << 'Consider configuring auto scaling for task instance groups' if task_instance_groups.any? && !has_auto_scaling?
            warnings << 'Consider multi-AZ deployment for notebook high availability' if uses_notebooks? && !is_multi_az?
            warnings
          end

          private

          def instance_cost_map
            { 'm5.xlarge' => 0.192, 'm5.2xlarge' => 0.384, 'm5.4xlarge' => 0.768, 'm5.12xlarge' => 2.304,
              'c5.xlarge' => 0.17, 'c5.2xlarge' => 0.34, 'c5.4xlarge' => 0.68,
              'r5.xlarge' => 0.252, 'r5.2xlarge' => 0.504, 'r5.4xlarge' => 1.008 }
          end

          def calculate_master_cost(costs)
            costs[master_instance_group[:instance_type]] || 0.20
          end

          def calculate_core_cost(costs)
            return 0.0 unless core_instance_group

            cost = costs[core_instance_group[:instance_type]] || 0.20
            cost * (core_instance_group[:instance_count] || 1)
          end

          def calculate_task_cost(costs)
            task_instance_groups.sum do |group|
              (costs[group[:instance_type]] || 0.20) * group[:instance_count]
            end
          end
        end
      end
    end
  end
end
