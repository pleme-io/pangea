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

require "dry-struct"
require_relative "enums"

module Pangea
  module Components
    module SpotInstanceCarbonOptimizer
      module Types
        # Output structure containing created resources
        class Output < Dry::Struct
          # Spot fleet requests (per region)
          attribute :spot_fleets, Types::Hash.map(Types::Strict::String, Types::Any)

          # Lambda functions
          attribute :carbon_monitor_function, Types::Any
          attribute :fleet_optimizer_function, Types::Any
          attribute :migration_orchestrator_function, Types::Any

          # DynamoDB tables
          attribute :fleet_state_table, Types::Any
          attribute :carbon_data_table, Types::Any
          attribute :migration_history_table, Types::Any

          # EventBridge rules
          attribute :optimization_schedule, Types::Any
          attribute :carbon_check_schedule, Types::Any
          attribute :spot_interruption_rule, Types::Any

          # CloudWatch components
          attribute :carbon_dashboard, Types::Any
          attribute :efficiency_metrics, Types::Array.of(Types::Any)
          attribute :carbon_alarms, Types::Array.of(Types::Any)

          # IAM roles
          attribute :fleet_role, Types::Any
          attribute :lambda_role, Types::Any

          def active_regions
            spot_fleets.keys
          end

          def total_capacity
            spot_fleets.values.sum { |fleet| fleet.target_capacity || 0 }
          end

          def dashboard_url
            "https://console.aws.amazon.com/cloudwatch/home?region=#{carbon_dashboard.region}#dashboards:name=#{carbon_dashboard.dashboard_name}"
          end
        end
      end
    end
  end
end
