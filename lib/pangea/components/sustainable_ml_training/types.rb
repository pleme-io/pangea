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
require "dry-types"

module Pangea
  module Components
    module SustainableMLTraining
      module Types
        include Dry.Types()
      end
    end
  end
end

require_relative "types/enums"
require_relative "types/constants"
require_relative "types/validations"

module Pangea
  module Components
    module SustainableMLTraining
      module Types
        # Input structure for sustainable ML training
        class Input < Dry::Struct
          attribute :name, Types::Strict::String
          attribute :model_type, ModelType

          # Training configuration
          attribute :training_strategy, TrainingStrategy.default('carbon_aware_scheduling')
          attribute :dataset_size_gb, Types::Coercible::Float
          attribute :estimated_training_hours, Types::Coercible::Float
          attribute :checkpoint_frequency_minutes, Types::Coercible::Integer.default(30)

          # Compute optimization
          attribute :compute_optimization, ComputeOptimization.default('mixed_precision')
          attribute :enable_model_compression, Types::Strict::Bool.default(true)
          attribute :target_model_size_reduction, Types::Coercible::Float.default(0.5)

          # Instance configuration
          attribute :instance_priority, InstancePriority.default('carbon_optimized')
          attribute :preferred_instance_types, Types::Array.of(Types::Strict::String).default([
            'ml.p4d.24xlarge',    # 8x A100 GPUs - most efficient
            'ml.p3.16xlarge',     # 8x V100 GPUs
            'ml.g5.48xlarge',     # 8x A10G GPUs - good perf/cost
            'ml.g4dn.12xlarge',   # 4x T4 GPUs - cost effective
            'ml.trn1.32xlarge'    # 16x Trainium - AWS ML chips
          ].freeze)
          attribute :min_gpu_memory_gb, Types::Coercible::Integer.default(16)

          # Carbon optimization
          attribute :carbon_intensity_threshold, Types::Coercible::Integer.default(150)
          attribute :preferred_training_regions, Types::Array.of(Types::Strict::String).default([
            'us-west-2',     # Oregon - renewable
            'eu-north-1',    # Stockholm - renewable
            'ca-central-1',  # Montreal - hydro
            'eu-west-1'      # Ireland - carbon neutral
          ].freeze)
          attribute :enable_cross_region_training, Types::Strict::Bool.default(true)

          # Spot instance configuration
          attribute :use_spot_instances, Types::Strict::Bool.default(true)
          attribute :spot_interruption_behavior, Types::Strict::String.default('checkpoint')
          attribute :max_spot_price_percentage, Types::Coercible::Integer.default(80)

          # Model efficiency settings
          attribute :enable_early_stopping, Types::Strict::Bool.default(true)
          attribute :early_stopping_patience, Types::Coercible::Integer.default(5)
          attribute :enable_automatic_mixed_precision, Types::Strict::Bool.default(true)
          attribute :enable_gradient_accumulation, Types::Strict::Bool.default(true)

          # Data efficiency
          attribute :enable_data_augmentation, Types::Strict::Bool.default(true)
          attribute :cache_dataset_in_memory, Types::Strict::Bool.default(false)
          attribute :num_data_loader_workers, Types::Coercible::Integer.default(4)

          # Monitoring and reporting
          attribute :track_carbon_emissions, Types::Strict::Bool.default(true)
          attribute :track_energy_usage, Types::Strict::Bool.default(true)
          attribute :enable_experiment_tracking, Types::Strict::Bool.default(true)

          # Storage configuration
          attribute :s3_bucket_name, Types::Strict::String
          attribute :use_fsx_lustre, Types::Strict::Bool.default(true)
          attribute :enable_model_caching, Types::Strict::Bool.default(true)

          # Tags
          attribute :tags, Types::Hash.map(Types::Coercible::String, Types::Coercible::String).default({})

          def self.example
            new(
              name: "sustainable-bert-training",
              model_type: "natural_language",
              dataset_size_gb: 100.0,
              estimated_training_hours: 24.0,
              s3_bucket_name: "my-ml-training-bucket",
              training_strategy: "carbon_aware_scheduling",
              compute_optimization: "mixed_precision",
              use_spot_instances: true,
              tags: {
                "Project" => "nlp-research",
                "Sustainability" => "optimized"
              }
            )
          end
        end

        # Output structure containing created resources
        class Output < Dry::Struct
          # SageMaker resources
          attribute :training_job, Types::Any
          attribute :model, Types::Any.optional
          attribute :endpoint, Types::Any.optional

          # Compute resources
          attribute :spot_fleet, Types::Any.optional
          attribute :instance_profile, Types::Any

          # Storage resources
          attribute :s3_bucket, Types::Any
          attribute :fsx_filesystem, Types::Any.optional
          attribute :model_cache_bucket, Types::Any.optional

          # Lambda functions
          attribute :carbon_scheduler_function, Types::Any
          attribute :training_optimizer_function, Types::Any
          attribute :efficiency_monitor_function, Types::Any

          # Monitoring resources
          attribute :experiment_tracking, Types::Any.optional
          attribute :carbon_dashboard, Types::Any
          attribute :training_metrics, Types::Array.of(Types::Any)
          attribute :efficiency_alarms, Types::Array.of(Types::Any)

          # DynamoDB tables
          attribute :training_state_table, Types::Any
          attribute :carbon_tracking_table, Types::Any

          # IAM roles
          attribute :sagemaker_role, Types::Any
          attribute :lambda_role, Types::Any

          def training_job_name
            training_job.training_job_name
          end

          def dashboard_url
            "https://console.aws.amazon.com/cloudwatch/home?region=#{carbon_dashboard.region}#dashboards:name=#{carbon_dashboard.dashboard_name}"
          end

          def model_artifacts_location
            "s3://#{s3_bucket.bucket}/models/"
          end
        end
      end
    end
  end
end
