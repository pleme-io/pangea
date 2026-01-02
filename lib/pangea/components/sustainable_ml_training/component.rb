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
require_relative "modules/tables"
require_relative "modules/compute"
require_relative "modules/functions"
require_relative "modules/training"
require_relative "modules/monitoring"
require_relative "modules/code_generators"

module Pangea
  module Components
    module SustainableMLTraining
      # Sustainable ML Training Component
      # Implements carbon-aware, efficient machine learning training infrastructure
      class Component
        include Pangea::DSL
        include Helpers
        include Roles
        include Storage
        include Tables
        include Compute
        include Functions
        include Training
        include Monitoring
        include CodeGenerators

        def self.build(input)
          new.build(input)
        end

        def build(input)
          input = Types::Input.new(input) unless input.is_a?(Types::Input)
          validate_input(input)

          # Create resources in dependency order
          resources = create_all_resources(input)

          # Build output
          Types::Output.new(resources)
        end

        private

        def validate_input(input)
          Types.validate_dataset_size(input.dataset_size_gb)
          Types.validate_training_hours(input.estimated_training_hours)
          Types.validate_carbon_threshold(input.carbon_intensity_threshold)
          Types.validate_model_compression(input.enable_model_compression, input.target_model_size_reduction)
        end

        def create_all_resources(input)
          # Create IAM roles
          sagemaker_role = create_sagemaker_role(input)
          lambda_role = create_lambda_role(input)

          # Create storage resources
          s3_bucket = create_s3_bucket(input)
          fsx_filesystem = input.use_fsx_lustre ? create_fsx_filesystem(input, s3_bucket) : nil
          model_cache_bucket = input.enable_model_caching ? create_model_cache_bucket(input) : nil

          # Create DynamoDB tables
          training_state_table = create_training_state_table(input)
          carbon_tracking_table = create_carbon_tracking_table(input)

          # Create Lambda functions
          carbon_scheduler = create_carbon_scheduler_function(input, lambda_role, training_state_table, carbon_tracking_table)
          training_optimizer = create_training_optimizer_function(input, lambda_role, training_state_table)
          efficiency_monitor = create_efficiency_monitor_function(input, lambda_role, carbon_tracking_table)

          # Create compute resources
          instance_profile = create_instance_profile(input, sagemaker_role)
          spot_fleet = input.use_spot_instances ? create_spot_fleet(input, instance_profile) : nil

          # Create training resources
          training_job = create_training_job(input, sagemaker_role, s3_bucket, fsx_filesystem)
          experiment_tracking = input.enable_experiment_tracking ? create_experiment_tracking(input) : nil

          # Create monitoring resources
          training_metrics = create_training_metrics(input)
          carbon_dashboard = create_carbon_dashboard(input, training_metrics)
          efficiency_alarms = create_efficiency_alarms(input, training_metrics)

          build_resources_hash(
            sagemaker_role: sagemaker_role,
            lambda_role: lambda_role,
            s3_bucket: s3_bucket,
            fsx_filesystem: fsx_filesystem,
            model_cache_bucket: model_cache_bucket,
            training_state_table: training_state_table,
            carbon_tracking_table: carbon_tracking_table,
            carbon_scheduler_function: carbon_scheduler,
            training_optimizer_function: training_optimizer,
            efficiency_monitor_function: efficiency_monitor,
            instance_profile: instance_profile,
            spot_fleet: spot_fleet,
            training_job: training_job,
            experiment_tracking: experiment_tracking,
            training_metrics: training_metrics,
            carbon_dashboard: carbon_dashboard,
            efficiency_alarms: efficiency_alarms
          )
        end

        def build_resources_hash(**resources)
          resources.merge(
            model: nil, # Created after training completes
            endpoint: nil # Created after model is ready
          )
        end
      end
    end
  end
end
