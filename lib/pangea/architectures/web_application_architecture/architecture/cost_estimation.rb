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
      class Architecture
        # Cost estimation methods
        module CostEstimation
          def calculate_monthly_cost(components, _resources)
            cost = 0.0
            cost += 22.0 if components[:load_balancer]
            cost += calculate_instance_costs(components[:web_servers])
            cost += calculate_database_costs(components[:database])
            cost += 15.0 if components[:cache]
            cost += 10.0 if components[:cdn]
            cost.round(2)
          end

          private

          def calculate_instance_costs(web_servers)
            return 0.0 unless web_servers&.[](:min_size)

            instance_cost = estimate_instance_cost(web_servers[:instance_type] || 't3.medium')
            instance_cost * web_servers[:min_size]
          end

          def calculate_database_costs(database)
            return 0.0 unless database

            estimate_database_cost(database[:instance_class] || 'db.t3.micro')
          end

          def estimate_instance_cost(instance_type)
            case instance_type
            when /t3\.micro/ then 8.5
            when /t3\.small/ then 17.0
            when /t3\.medium/ then 34.0
            when /t3\.large/ then 67.0
            when /c5\.large/ then 72.0
            else 50.0
            end
          end

          def estimate_database_cost(instance_class)
            case instance_class
            when /db\.t3\.micro/ then 16.0
            when /db\.t3\.small/ then 32.0
            when /db\.r5\.large/ then 180.0
            else 80.0
            end
          end
        end
      end
    end
  end
end
