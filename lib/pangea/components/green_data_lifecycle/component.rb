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
require_relative "modules/storage"
require_relative "modules/lifecycle"
require_relative "modules/glacier"
require_relative "modules/functions"
require_relative "modules/inventory"
require_relative "modules/monitoring"
require_relative "modules/code_generators"

module Pangea
  module Components
    module GreenDataLifecycle
      class Component
        include Pangea::DSL
        include Helpers
        include Roles
        include Storage
        include Lifecycle
        include Glacier
        include Functions
        include Inventory
        include Monitoring
        include CodeGenerators

        def self.build(input)
          new.build(input)
        end

        def build(input)
          input = Types::Input.new(input) unless input.is_a?(Types::Input)
          validate_input(input)

          # Create core resources
          lifecycle_role = create_lifecycle_role(input)
          analyzer_role = create_analyzer_role(input)
          primary_bucket = create_primary_bucket(input)
          archive_bucket = create_archive_bucket(input) if input.enable_glacier_archive

          # Create lifecycle and storage configurations
          lifecycle_configuration = create_lifecycle_configuration(input, primary_bucket)
          intelligent_tiering = create_intelligent_tiering(input, primary_bucket)
          glacier_vault = create_glacier_vault(input) if input.enable_glacier_archive

          # Create Lambda functions
          functions = create_lambda_functions(input, analyzer_role, primary_bucket)

          # Create inventory and monitoring
          inventory_configuration = create_inventory(input, primary_bucket)
          monitoring = create_monitoring_resources(input, primary_bucket)

          build_output(
            input, primary_bucket, archive_bucket, lifecycle_configuration,
            intelligent_tiering, glacier_vault, functions, monitoring,
            inventory_configuration, lifecycle_role, analyzer_role
          )
        end

        private

        def validate_input(input)
          Types.validate_transition_days(
            input.transition_to_ia_days,
            input.transition_to_glacier_ir_days,
            input.transition_to_glacier_days,
            input.transition_to_deep_archive_days
          )
          Types.validate_carbon_threshold(input.carbon_threshold_gco2_per_gb)
          Types.validate_access_window(input.access_pattern_window_days)
        end

        def create_intelligent_tiering(input, bucket)
          return nil unless input.enable_intelligent_tiering

          create_intelligent_tiering_configuration(input, bucket)
        end

        def create_lambda_functions(input, role, bucket)
          {
            access_analyzer: create_access_analyzer_function(input, role, bucket),
            carbon_optimizer: create_carbon_optimizer_function(input, role, bucket),
            lifecycle_manager: create_lifecycle_manager_function(input, role, bucket)
          }
        end

        def create_inventory(input, bucket)
          return nil unless input.enable_inventory

          create_inventory_configuration(input, bucket)
        end

        def create_monitoring_resources(input, bucket)
          storage_metrics = create_storage_metrics(input, bucket)
          {
            storage_metrics: storage_metrics,
            carbon_dashboard: create_carbon_dashboard(input, bucket, storage_metrics),
            efficiency_alarms: create_efficiency_alarms(input, storage_metrics)
          }
        end

        def build_output(input, primary_bucket, archive_bucket, lifecycle_config,
                         intelligent_tiering, glacier_vault, functions, monitoring,
                         inventory_config, lifecycle_role, analyzer_role)
          Types::Output.new(
            primary_bucket: primary_bucket,
            archive_bucket: archive_bucket,
            lifecycle_configuration: lifecycle_config,
            intelligent_tiering_configuration: intelligent_tiering,
            glacier_vault: glacier_vault,
            access_analyzer_function: functions[:access_analyzer],
            carbon_optimizer_function: functions[:carbon_optimizer],
            lifecycle_manager_function: functions[:lifecycle_manager],
            storage_metrics: monitoring[:storage_metrics],
            carbon_dashboard: monitoring[:carbon_dashboard],
            efficiency_alarms: monitoring[:efficiency_alarms],
            inventory_configuration: inventory_config,
            lifecycle_role: lifecycle_role,
            analyzer_role: analyzer_role
          )
        end
      end
    end
  end
end
