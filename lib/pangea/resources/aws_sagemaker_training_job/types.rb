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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # SageMaker Training Job instance types
        SageMakerTrainingInstanceType = String.enum(
          # General purpose
          'ml.m4.xlarge', 'ml.m4.2xlarge', 'ml.m4.4xlarge', 'ml.m4.10xlarge', 'ml.m4.16xlarge',
          'ml.m5.large', 'ml.m5.xlarge', 'ml.m5.2xlarge', 'ml.m5.4xlarge', 'ml.m5.12xlarge', 'ml.m5.24xlarge',
          'ml.m5.48xlarge',
          # Compute optimized
          'ml.c4.xlarge', 'ml.c4.2xlarge', 'ml.c4.4xlarge', 'ml.c4.8xlarge',
          'ml.c5.xlarge', 'ml.c5.2xlarge', 'ml.c5.4xlarge', 'ml.c5.9xlarge', 'ml.c5.18xlarge',
          'ml.c5n.xlarge', 'ml.c5n.2xlarge', 'ml.c5n.4xlarge', 'ml.c5n.9xlarge', 'ml.c5n.18xlarge',
          # Memory optimized
          'ml.r5.large', 'ml.r5.xlarge', 'ml.r5.2xlarge', 'ml.r5.4xlarge', 'ml.r5.12xlarge', 'ml.r5.24xlarge',
          # GPU instances
          'ml.p2.xlarge', 'ml.p2.8xlarge', 'ml.p2.16xlarge',
          'ml.p3.2xlarge', 'ml.p3.8xlarge', 'ml.p3.16xlarge',
          'ml.p3dn.24xlarge', 'ml.p4d.24xlarge',
          'ml.g4dn.xlarge', 'ml.g4dn.2xlarge', 'ml.g4dn.4xlarge', 'ml.g4dn.8xlarge', 'ml.g4dn.12xlarge', 'ml.g4dn.16xlarge'
        )
        
        # SageMaker Training Job input modes
        SageMakerTrainingInputMode = String.enum('File', 'Pipe')
        
        # SageMaker Training Job compression types
        SageMakerTrainingCompressionType = String.enum('None', 'Gzip')
        
        # SageMaker Training Job content types
        SageMakerTrainingContentType = String.enum(
          'text/csv', 'text/libsvm', 'application/x-parquet', 'application/json',
          'application/jsonlines', 'application/x-recordio-protobuf',
          'application/x-image', 'application/x-numpy'
        )
        
        # SageMaker Training Job data source
        SageMakerTrainingDataSource = Hash.schema(
          s3_data_source: Hash.schema(
            s3_data_type: String.enum('ManifestFile', 'S3Prefix', 'AugmentedManifestFile'),
            s3_uri: String.constrained(format: /\As3:\/\//),
            s3_data_distribution_type?: String.enum('FullyReplicated', 'ShardedByS3Key').default('FullyReplicated'),
            attribute_names?: Array.of(String).optional
          )
        )
        
        # SageMaker Training Job input data configuration
        SageMakerTrainingInputDataConfig = Hash.schema(
          channel_name: String.constrained(
            min_size: 1,
            max_size: 64,
            format: /\A[a-zA-Z0-9\-]+\z/
          ),
          data_source: SageMakerTrainingDataSource,
          content_type?: SageMakerTrainingContentType.optional,
          compression_type?: SageMakerTrainingCompressionType.default('None'),
          record_wrapper_type?: String.enum('None', 'RecordIO').default('None'),
          input_mode?: SageMakerTrainingInputMode.default('File'),
          shuffle_config?: Hash.schema(
            seed: Integer.constrained(gteq: 0, lteq: 4294967295)
          ).optional
        )
        
        # SageMaker Training Job output data configuration
        SageMakerTrainingOutputDataConfig = Hash.schema(
          kms_key_id?: String.optional,
          s3_output_path: String.constrained(format: /\As3:\/\//)
        )
        
        # SageMaker Training Job resource configuration
        SageMakerTrainingResourceConfig = Hash.schema(
          instance_count: Integer.constrained(gteq: 1, lteq: 100),
          instance_type: SageMakerTrainingInstanceType,
          volume_size_in_gb: Integer.constrained(gteq: 1, lteq: 16384),
          volume_kms_key_id?: String.optional
        )
        
        # SageMaker Training Job stopping condition
        SageMakerTrainingStoppingCondition = Hash.schema(
          max_runtime_in_seconds?: Integer.constrained(gteq: 1, lteq: 432000).default(86400)
        )
        
        # SageMaker Training Job VPC configuration
        SageMakerTrainingVpcConfig = Hash.schema(
          security_group_ids: Array.of(String).constrained(min_size: 1, max_size: 5),
          subnets: Array.of(String).constrained(min_size: 1, max_size: 16)
        )
        
        # SageMaker Training Job checkpoint configuration
        SageMakerTrainingCheckpointConfig = Hash.schema(
          s3_uri: String.constrained(format: /\As3:\/\//),
          local_path?: String.default('/opt/ml/checkpoints')
        )
        
        # SageMaker Training Job debug hook configuration
        SageMakerTrainingDebugHookConfig = Hash.schema(
          local_path?: String.default('/opt/ml/output/tensors'),
          s3_output_path: String.constrained(format: /\As3:\/\//),
          hook_parameters?: Hash.map(String, String).optional,
          collection_configurations?: Array.of(
            Hash.schema(
              collection_name?: String.optional,
              collection_parameters?: Hash.map(String, String).optional
            )
          ).optional
        )
        
        # SageMaker Training Job profiler configuration
        SageMakerTrainingProfilerConfig = Hash.schema(
          s3_output_path?: String.constrained(format: /\As3:\/\//).optional,
          profiling_interval_in_milliseconds?: Integer.constrained(gteq: 100, lteq: 3600000).default(500),
          profiling_parameters?: Hash.map(String, String).optional
        )
        
        # SageMaker Training Job attributes with comprehensive ML training validation
        class SageMakerTrainingJobAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :training_job_name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 63,
            format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/
          )
          attribute :role_arn, Resources::Types::String.constrained(
            format: /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9_+=,.@-]+\z/
          )
          attribute :algorithm_specification, Resources::Types::Hash.schema(
            training_image?: String.optional,
            algorithm_name?: String.optional,
            training_input_mode: SageMakerTrainingInputMode,
            metric_definitions?: Array.of(
              Hash.schema(
                name: String.constrained(
                  min_size: 1,
                  max_size: 255,
                  format: /\A[a-zA-Z0-9\-_:]+\z/
                ),
                regex: String.constrained(min_size: 1, max_size: 500)
              )
            ).optional,
            enable_sage_maker_metrics_time_series?: Bool.default(true)
          )
          attribute :input_data_config, Resources::Types::Array.of(SageMakerTrainingInputDataConfig).constrained(min_size: 1, max_size: 20)
          attribute :output_data_config, SageMakerTrainingOutputDataConfig
          attribute :resource_config, SageMakerTrainingResourceConfig
          attribute :stopping_condition, SageMakerTrainingStoppingCondition
          
          # Optional attributes
          attribute :hyper_parameters, Resources::Types::Hash.map(String, String).optional
          attribute :vpc_config, SageMakerTrainingVpcConfig.optional
          attribute :checkpoint_config, SageMakerTrainingCheckpointConfig.optional
          attribute :debug_hook_config, SageMakerTrainingDebugHookConfig.optional
          attribute :debug_rule_configurations, Resources::Types::Array.of(
            Hash.schema(
              rule_configuration_name: String,
              local_path?: String.optional,
              s3_output_path?: String.optional,
              rule_evaluator_image: String,
              instance_type?: String.enum('ml.t3.medium', 'ml.t3.large', 'ml.t3.xlarge', 'ml.t3.2xlarge', 'ml.m4.xlarge', 'ml.m4.2xlarge', 'ml.m4.4xlarge', 'ml.m5.large', 'ml.m5.xlarge', 'ml.m5.2xlarge', 'ml.m5.4xlarge', 'ml.c4.xlarge', 'ml.c4.2xlarge', 'ml.c4.4xlarge', 'ml.c4.8xlarge', 'ml.c5.xlarge', 'ml.c5.2xlarge', 'ml.c5.4xlarge', 'ml.c5.9xlarge', 'ml.c5.18xlarge').optional,
              volume_size_in_gb?: Integer.constrained(gteq: 1, lteq: 16384).optional,
              rule_parameters?: Hash.map(String, String).optional
            )
          ).optional
          attribute :profiler_config, SageMakerTrainingProfilerConfig.optional
          attribute :profiler_rule_configurations, Resources::Types::Array.of(
            Hash.schema(
              rule_configuration_name: String,
              local_path?: String.optional,
              s3_output_path?: String.optional,
              rule_evaluator_image: String,
              instance_type?: String.optional,
              volume_size_in_gb?: Integer.constrained(gteq: 1, lteq: 16384).optional,
              rule_parameters?: Hash.map(String, String).optional
            )
          ).optional
          attribute :experiment_config, Resources::Types::Hash.schema(
            experiment_name?: String.optional,
            trial_name?: String.optional,
            trial_component_display_name?: String.optional
          ).optional
          attribute :tensor_board_output_config, Resources::Types::Hash.schema(
            local_path?: String.default('/opt/ml/output/tensorboard'),
            s3_output_path: String.constrained(format: /\As3:\/\//)
          ).optional
          attribute :enable_network_isolation, Resources::Types::Bool.default(false)
          attribute :enable_inter_container_traffic_encryption, Resources::Types::Bool.default(false)
          attribute :enable_managed_spot_training, Resources::Types::Bool.default(false)
          attribute :retry_strategy, Resources::Types::Hash.schema(
            maximum_retry_attempts: Integer.constrained(gteq: 1, lteq: 10)
          ).optional
          attribute :environment, Resources::Types::Hash.map(String, String).optional
          attribute :tags, Resources::Types::AwsTags
          
          # Custom validation for SageMaker Training Job
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate algorithm specification
            algo_spec = attrs[:algorithm_specification]
            if algo_spec
              has_image = algo_spec[:training_image]
              has_algorithm = algo_spec[:algorithm_name]
              
              if !has_image && !has_algorithm
                raise Dry::Struct::Error, "Either training_image or algorithm_name must be specified"
              end
              
              if has_image && has_algorithm
                raise Dry::Struct::Error, "Cannot specify both training_image and algorithm_name"
              end
              
              # Validate metric definitions
              if algo_spec[:metric_definitions]
                algo_spec[:metric_definitions].each_with_index do |metric, index|
                  begin
                    Regexp.new(metric[:regex])
                  rescue RegexpError => e
                    raise Dry::Struct::Error, "Metric definition #{index}: Invalid regex '#{metric[:regex]}': #{e.message}"
                  end
                end
              end
            end
            
            # Validate input data channels have unique names
            if attrs[:input_data_config]
              channel_names = attrs[:input_data_config].map { |config| config[:channel_name] }
              if channel_names.uniq.size != channel_names.size
                raise Dry::Struct::Error, "Input data channel names must be unique"
              end
            end
            
            # Validate managed spot training configuration
            if attrs[:enable_managed_spot_training]
              stopping_condition = attrs[:stopping_condition]
              if stopping_condition && stopping_condition[:max_runtime_in_seconds]
                max_runtime = stopping_condition[:max_runtime_in_seconds]
                if max_runtime > 172800 # 48 hours
                  raise Dry::Struct::Error, "Managed spot training max runtime cannot exceed 48 hours (172800 seconds)"
                end
              end
            end
            
            # Validate VPC configuration
            if attrs[:enable_network_isolation] && attrs[:vpc_config]
              raise Dry::Struct::Error, "VPC configuration cannot be specified when network isolation is enabled"
            end
            
            # Validate checkpoint configuration with managed spot training
            if attrs[:enable_managed_spot_training] && !attrs[:checkpoint_config]
              # Warning: Checkpointing is highly recommended for spot training
            end
            
            # Validate profiler configuration
            if attrs[:profiler_config] && attrs[:profiler_rule_configurations]
              profiler_rules = attrs[:profiler_rule_configurations]
              if profiler_rules.empty?
                raise Dry::Struct::Error, "At least one profiler rule configuration is required when profiler_config is specified"
              end
            end
            
            # Validate resource configuration for distributed training
            resource_config = attrs[:resource_config]
            if resource_config && resource_config[:instance_count] > 1
              # Validate input mode for distributed training
              if attrs[:input_data_config]
                attrs[:input_data_config].each do |config|
                  if config[:input_mode] == 'Pipe' && resource_config[:instance_count] > 1
                    raise Dry::Struct::Error, "Pipe input mode is not supported for distributed training (instance_count > 1)"
                  end
                end
              end
            end
            
            # Validate hyperparameter values
            if attrs[:hyper_parameters]
              attrs[:hyper_parameters].each do |key, value|
                if value.length > 2500
                  raise Dry::Struct::Error, "Hyperparameter '#{key}' value exceeds maximum length of 2500 characters"
                end
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def estimated_training_cost
            instance_cost = get_training_instance_cost_per_hour * resource_config[:instance_count]
            storage_cost = get_storage_cost_per_hour
            
            max_runtime_hours = (stopping_condition[:max_runtime_in_seconds] || 86400) / 3600.0
            spot_discount = enable_managed_spot_training ? 0.7 : 1.0 # Estimate 30% savings with spot
            
            (instance_cost + storage_cost) * max_runtime_hours * spot_discount
          end
          
          def get_training_instance_cost_per_hour
            # Simplified pricing lookup
            case resource_config[:instance_type]
            when /^ml\.m4/ then 0.20
            when /^ml\.m5\.large/ then 0.115
            when /^ml\.m5\.xlarge/ then 0.23
            when /^ml\.m5\.2xlarge/ then 0.46
            when /^ml\.c4/ then 0.15
            when /^ml\.c5/ then 0.20
            when /^ml\.p2\.xlarge/ then 0.90
            when /^ml\.p3\.2xlarge/ then 3.06
            when /^ml\.p3\.8xlarge/ then 12.24
            when /^ml\.p3\.16xlarge/ then 24.48
            when /^ml\.g4dn/ then 1.20
            else 0.25
            end
          end
          
          def get_storage_cost_per_hour
            # EBS storage cost (very minimal)
            (resource_config[:volume_size_in_gb] * 0.10) / (24 * 30) # Monthly cost divided by hours
          end
          
          def is_distributed_training?
            resource_config[:instance_count] > 1
          end
          
          def is_gpu_training?
            resource_config[:instance_type].match?(/ml\.(p|g)/)
          end
          
          def uses_spot_training?
            enable_managed_spot_training
          end
          
          def uses_network_isolation?
            enable_network_isolation
          end
          
          def uses_vpc?
            !vpc_config.nil?
          end
          
          def has_checkpoints?
            !checkpoint_config.nil?
          end
          
          def has_debugging?
            !debug_hook_config.nil? || (debug_rule_configurations && debug_rule_configurations.any?)
          end
          
          def has_profiling?
            !profiler_config.nil? || (profiler_rule_configurations && profiler_rule_configurations.any?)
          end
          
          def has_tensorboard?
            !tensor_board_output_config.nil?
          end
          
          def has_experiment_tracking?
            !experiment_config.nil?
          end
          
          def uses_encryption?
            enable_inter_container_traffic_encryption || 
            !resource_config[:volume_kms_key_id].nil? ||
            !output_data_config[:kms_key_id].nil?
          end
          
          def input_channel_count
            input_data_config.size
          end
          
          def metric_definition_count
            algorithm_specification[:metric_definitions]&.size || 0
          end
          
          def hyperparameter_count
            hyper_parameters&.size || 0
          end
          
          def max_runtime_hours
            (stopping_condition[:max_runtime_in_seconds] || 86400) / 3600.0
          end
          
          # Training job capability analysis
          def training_capabilities
            {
              distributed: is_distributed_training?,
              gpu_enabled: is_gpu_training?,
              spot_training: uses_spot_training?,
              network_isolated: uses_network_isolation?,
              vpc_enabled: uses_vpc?,
              checkpointing: has_checkpoints?,
              debugging: has_debugging?,
              profiling: has_profiling?,
              tensorboard: has_tensorboard?,
              experiment_tracking: has_experiment_tracking?,
              encrypted: uses_encryption?
            }
          end
          
          # Security and best practices assessment
          def security_score
            score = 0
            score += 20 if uses_network_isolation?
            score += 15 if uses_vpc?
            score += 10 if enable_inter_container_traffic_encryption
            score += 10 if resource_config[:volume_kms_key_id]
            score += 10 if output_data_config[:kms_key_id]
            score += 15 if has_checkpoints? && uses_spot_training?
            score += 10 if has_debugging? || has_profiling?
            score += 10 if retry_strategy && retry_strategy[:maximum_retry_attempts] > 1
            
            [score, 100].min
          end
          
          def best_practices_status
            issues = []
            issues << "No network isolation enabled" unless uses_network_isolation?
            issues << "No VPC configuration for network security" unless uses_vpc?
            issues << "No inter-container traffic encryption" unless enable_inter_container_traffic_encryption
            issues << "No KMS encryption for training volume" unless resource_config[:volume_kms_key_id]
            issues << "No KMS encryption for output data" unless output_data_config[:kms_key_id]
            issues << "Spot training without checkpointing" if uses_spot_training? && !has_checkpoints?
            issues << "No debugging or profiling configured" unless has_debugging? || has_profiling?
            issues << "No retry strategy for training failures" unless retry_strategy
            
            {
              status: issues.empty? ? 'optimal' : 'needs_improvement',
              issues: issues
            }
          end
          
          # Training job summary
          def training_summary
            {
              training_job_name: training_job_name,
              instance_type: resource_config[:instance_type],
              instance_count: resource_config[:instance_count],
              max_runtime_hours: max_runtime_hours,
              estimated_cost: estimated_training_cost,
              capabilities: training_capabilities,
              security_score: security_score,
              uses_spot: uses_spot_training?,
              has_checkpoints: has_checkpoints?,
              input_channels: input_channel_count,
              hyperparameters: hyperparameter_count
            }
          end
        end
      end
    end
  end
end