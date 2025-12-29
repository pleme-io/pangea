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

require_relative "types"
require_relative "modules/helpers"
require_relative "modules/roles"
require_relative "modules/tables"
require_relative "modules/fleets"
require_relative "modules/functions"
require_relative "modules/schedules"
require_relative "modules/monitoring"
require_relative "modules/code_generators"

module Pangea
  module Components
    module SpotInstanceCarbonOptimizer
      # Spot Instance Carbon Optimizer Component
      # Orchestrates spot fleet management with carbon-aware optimization
      class Component
        include Pangea::DSL
        include Helpers
        include Roles
        include Tables
        include Fleets
        include Functions
        include Schedules
        include Monitoring
        include CodeGenerators

        def self.build(input)
          new.build(input)
        end

        def build(input)
          input = Types::Input.new(input) unless input.is_a?(Types::Input)

          validate_input(input)

          # Create IAM roles
          fleet_role = create_fleet_role(input)
          lambda_role = create_lambda_role(input)

          # Create DynamoDB tables
          fleet_state_table = create_fleet_state_table(input)
          carbon_data_table = create_carbon_data_table(input)
          migration_history_table = create_migration_history_table(input)

          # Create Spot fleet requests in each region
          spot_fleets = create_regional_spot_fleets(input, fleet_role, fleet_state_table)

          # Create Lambda functions
          carbon_monitor = create_carbon_monitor_function(input, lambda_role, carbon_data_table)
          fleet_optimizer = create_fleet_optimizer_function(
            input, lambda_role, fleet_state_table, carbon_data_table
          )
          migration_orchestrator = create_migration_orchestrator_function(
            input, lambda_role, fleet_state_table, migration_history_table
          )

          # Create EventBridge schedules
          optimization_schedule = create_optimization_schedule(input, fleet_optimizer)
          carbon_check_schedule = create_carbon_check_schedule(input, carbon_monitor)
          spot_interruption_rule = create_spot_interruption_rule(input, migration_orchestrator)

          # Create CloudWatch monitoring
          efficiency_metrics = create_efficiency_metrics(input)
          carbon_dashboard = create_carbon_dashboard(input, spot_fleets, efficiency_metrics)
          carbon_alarms = create_carbon_alarms(input, efficiency_metrics)

          build_output(
            spot_fleets: spot_fleets,
            carbon_monitor: carbon_monitor,
            fleet_optimizer: fleet_optimizer,
            migration_orchestrator: migration_orchestrator,
            fleet_state_table: fleet_state_table,
            carbon_data_table: carbon_data_table,
            migration_history_table: migration_history_table,
            optimization_schedule: optimization_schedule,
            carbon_check_schedule: carbon_check_schedule,
            spot_interruption_rule: spot_interruption_rule,
            carbon_dashboard: carbon_dashboard,
            efficiency_metrics: efficiency_metrics,
            carbon_alarms: carbon_alarms,
            fleet_role: fleet_role,
            lambda_role: lambda_role
          )
        end

        private

        def validate_input(input)
          Types.validate_capacity(input.target_capacity)
          Types.validate_carbon_threshold(input.carbon_intensity_threshold)
          Types.validate_regions(input.allowed_regions, input.preferred_regions)
          Types.validate_spot_block_duration(input.use_spot_blocks, input.spot_block_duration_hours)
        end

        def build_output(resources)
          Types::Output.new(
            spot_fleets: resources[:spot_fleets],
            carbon_monitor_function: resources[:carbon_monitor],
            fleet_optimizer_function: resources[:fleet_optimizer],
            migration_orchestrator_function: resources[:migration_orchestrator],
            fleet_state_table: resources[:fleet_state_table],
            carbon_data_table: resources[:carbon_data_table],
            migration_history_table: resources[:migration_history_table],
            optimization_schedule: resources[:optimization_schedule],
            carbon_check_schedule: resources[:carbon_check_schedule],
            spot_interruption_rule: resources[:spot_interruption_rule],
            carbon_dashboard: resources[:carbon_dashboard],
            efficiency_metrics: resources[:efficiency_metrics],
            carbon_alarms: resources[:carbon_alarms],
            fleet_role: resources[:fleet_role],
            lambda_role: resources[:lambda_role]
          )
        end
      end
    end
  end
end
