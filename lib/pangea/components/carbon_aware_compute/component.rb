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
require_relative "modules/functions"
require_relative "modules/schedules"
require_relative "modules/monitoring"
require_relative "modules/code_generators"

module Pangea
  module Components
    module CarbonAwareCompute
      class Component
        include Pangea::DSL
        include Helpers
        include Roles
        include Tables
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

          resources = create_resources(input)

          build_output(input, resources)
        end

        private

        def validate_input(input)
          Types.validate_carbon_threshold(input.carbon_intensity_threshold)
          Types.validate_execution_window(input.min_execution_window_hours, input.max_execution_window_hours)
          Types.validate_deadline(input.deadline_hours, input.max_execution_window_hours)
        end

        def create_resources(input)
          # Create IAM roles
          execution_role = create_execution_role(input)
          scheduler_role = create_scheduler_role(input)

          # Create DynamoDB tables
          workload_table = create_workload_table(input)
          carbon_data_table = create_carbon_data_table(input)

          # Create Lambda functions
          scheduler_function = create_scheduler_function(input, execution_role, workload_table, carbon_data_table)
          executor_function = create_executor_function(input, execution_role, workload_table)
          monitor_function = create_monitor_function(input, execution_role, carbon_data_table)

          # Create EventBridge rules
          scheduler_rule = create_scheduler_rule(input, scheduler_function, scheduler_role)
          carbon_check_rule = create_carbon_check_rule(input, monitor_function, scheduler_role)

          # Create CloudWatch metrics and dashboard
          carbon_metric = create_carbon_metric(input)
          efficiency_metric = create_efficiency_metric(input)
          dashboard = create_monitoring_dashboard(input, carbon_metric, efficiency_metric)

          # Create optional alarms
          high_carbon_alarm = input.alert_on_high_carbon ? create_high_carbon_alarm(input, carbon_metric) : nil
          efficiency_alarm = input.enable_cost_optimization ? create_efficiency_alarm(input, efficiency_metric) : nil

          {
            execution_role: execution_role,
            scheduler_role: scheduler_role,
            workload_table: workload_table,
            carbon_data_table: carbon_data_table,
            scheduler_function: scheduler_function,
            executor_function: executor_function,
            monitor_function: monitor_function,
            scheduler_rule: scheduler_rule,
            carbon_check_rule: carbon_check_rule,
            carbon_metric: carbon_metric,
            efficiency_metric: efficiency_metric,
            dashboard: dashboard,
            high_carbon_alarm: high_carbon_alarm,
            efficiency_alarm: efficiency_alarm
          }
        end

        def build_output(_input, resources)
          Types::Output.new(
            scheduler_function: resources[:scheduler_function],
            executor_function: resources[:executor_function],
            monitor_function: resources[:monitor_function],
            scheduler_rule: resources[:scheduler_rule],
            carbon_check_rule: resources[:carbon_check_rule],
            workload_table: resources[:workload_table],
            carbon_data_table: resources[:carbon_data_table],
            carbon_metric: resources[:carbon_metric],
            efficiency_metric: resources[:efficiency_metric],
            dashboard: resources[:dashboard],
            high_carbon_alarm: resources[:high_carbon_alarm],
            efficiency_alarm: resources[:efficiency_alarm],
            execution_role: resources[:execution_role],
            scheduler_role: resources[:scheduler_role]
          )
        end
      end
    end
  end
end
