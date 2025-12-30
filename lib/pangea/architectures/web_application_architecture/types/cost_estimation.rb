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
  module Architectures
    module WebApplicationArchitecture
      module Types
        # Cost estimation helpers for web application architecture
        module CostEstimation
          INSTANCE_COSTS = {
            /t3\.micro/ => 8.5,
            /t3\.small/ => 17.0,
            /t3\.medium/ => 34.0,
            /t3\.large/ => 67.0,
            /c5\.large/ => 72.0
          }.freeze

          DATABASE_COSTS = {
            /db\.t3\.micro/ => 16.0,
            /db\.t3\.small/ => 32.0,
            /db\.r5\.large/ => 180.0
          }.freeze

          ALB_BASE_COST = 22.0
          CACHING_COST = 15.0
          CDN_COST = 10.0
          STORAGE_COST = 5.0
          DEFAULT_INSTANCE_COST = 50.0
          DEFAULT_DATABASE_COST = 80.0

          module_function

          def estimate_monthly_cost(attributes)
            cost = ALB_BASE_COST

            cost += compute_instance_cost(attributes)
            cost += compute_database_cost(attributes)
            cost += CACHING_COST if attributes[:enable_caching]
            cost += CDN_COST if attributes[:enable_cdn]
            cost += STORAGE_COST

            apply_environment_multiplier(cost, attributes[:environment]).round(2)
          end

          def compute_instance_cost(attributes)
            instance_cost = find_cost(attributes[:instance_type], INSTANCE_COSTS, DEFAULT_INSTANCE_COST)
            instance_cost * attributes[:auto_scaling][:min]
          end

          def compute_database_cost(attributes)
            return 0.0 unless attributes[:database_enabled]

            db_cost = find_cost(attributes[:database_instance_class], DATABASE_COSTS, DEFAULT_DATABASE_COST)
            db_cost += db_cost * 0.5 if attributes[:high_availability]
            db_cost
          end

          def find_cost(type, cost_map, default)
            cost_map.each do |pattern, cost|
              return cost if type.match?(pattern)
            end
            default
          end

          def apply_environment_multiplier(cost, environment)
            case environment
            when 'production' then cost * 1.2
            when 'staging' then cost * 1.1
            else cost
            end
          end
        end
      end
    end
  end
end
