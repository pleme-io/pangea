# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        class SageMakerTrainingJobAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :training_job_name, Resources::Types::String.constrained(min_size: 1, max_size: 63, format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/)
          attribute :role_arn, Resources::Types::String.constrained(format: /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9_+=,.@-]+\z/)
          attribute :algorithm_specification, Resources::Types::Hash
          attribute :input_data_config, Resources::Types::Array.of(SageMakerTrainingInputDataConfig).constrained(min_size: 1, max_size: 20)
          attribute :output_data_config, SageMakerTrainingOutputDataConfig
          attribute :resource_config, SageMakerTrainingResourceConfig
          attribute :stopping_condition, SageMakerTrainingStoppingCondition
          attribute :hyper_parameters, Resources::Types::Hash.map(String, String).optional
          attribute :vpc_config, SageMakerTrainingVpcConfig.optional
          attribute :checkpoint_config, SageMakerTrainingCheckpointConfig.optional
          attribute :debug_hook_config, SageMakerTrainingDebugHookConfig.optional
          attribute :debug_rule_configurations, Resources::Types::Array.of(Hash).optional
          attribute :profiler_config, SageMakerTrainingProfilerConfig.optional
          attribute :profiler_rule_configurations, Resources::Types::Array.of(Hash).optional
          attribute :experiment_config, Resources::Types::Hash.optional
          attribute :tensor_board_output_config, Resources::Types::Hash.optional
          attribute :enable_network_isolation, Resources::Types::Bool.default(false)
          attribute :enable_inter_container_traffic_encryption, Resources::Types::Bool.default(false)
          attribute :enable_managed_spot_training, Resources::Types::Bool.default(false)
          attribute :retry_strategy, Resources::Types::Hash.optional
          attribute :environment, Resources::Types::Hash.map(String, String).optional
          attribute :tags, Resources::Types::AwsTags

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            SageMakerValidation.validate(attrs)
            super(attrs)
          end

          def is_distributed_training? = resource_config[:instance_count] > 1
          def is_gpu_training? = resource_config[:instance_type].match?(/ml\.(p|g)/)
          def uses_spot_training? = enable_managed_spot_training
          def uses_network_isolation? = enable_network_isolation
          def uses_vpc? = !vpc_config.nil?
          def has_checkpoints? = !checkpoint_config.nil?
          def has_debugging? = !debug_hook_config.nil? || debug_rule_configurations&.any?
          def has_profiling? = !profiler_config.nil? || profiler_rule_configurations&.any?
          def has_tensorboard? = !tensor_board_output_config.nil?
          def has_experiment_tracking? = !experiment_config.nil?
          def uses_encryption? = enable_inter_container_traffic_encryption || !resource_config[:volume_kms_key_id].nil? || !output_data_config[:kms_key_id].nil?
          def input_channel_count = input_data_config.size
          def metric_definition_count = algorithm_specification[:metric_definitions]&.size || 0
          def hyperparameter_count = hyper_parameters&.size || 0
          def max_runtime_hours = (stopping_condition[:max_runtime_in_seconds] || 86_400) / 3600.0

          def estimated_training_cost
            instance_cost = SageMakerCostCalculator.instance_cost(resource_config[:instance_type]) * resource_config[:instance_count]
            storage_cost = (resource_config[:volume_size_in_gb] * 0.10) / (24 * 30)
            total = (instance_cost + storage_cost) * max_runtime_hours
            enable_managed_spot_training ? total * 0.3 : total
          end

          def training_capabilities
            { distributed: is_distributed_training?, gpu_enabled: is_gpu_training?, spot_training: uses_spot_training?,
              network_isolated: uses_network_isolation?, vpc_enabled: uses_vpc?, checkpointing: has_checkpoints?,
              debugging: has_debugging?, profiling: has_profiling?, tensorboard: has_tensorboard?, experiment_tracking: has_experiment_tracking?, encrypted: uses_encryption? }
          end

          def security_score
            score = 0
            score += 20 if uses_network_isolation?
            score += 15 if uses_vpc?
            score += 10 if enable_inter_container_traffic_encryption
            score += 10 if resource_config[:volume_kms_key_id]
            score += 10 if output_data_config[:kms_key_id]
            score += 15 if has_checkpoints? && uses_spot_training?
            score += 10 if has_debugging? || has_profiling?
            score += 10 if retry_strategy&.dig(:maximum_retry_attempts).to_i > 1
            [score, 100].min
          end
        end
      end
    end
  end
end
