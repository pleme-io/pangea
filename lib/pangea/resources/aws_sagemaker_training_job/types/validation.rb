# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module SageMakerValidation
          def self.validate(attrs)
            validate_algorithm(attrs[:algorithm_specification])
            validate_channels(attrs[:input_data_config])
            validate_spot_config(attrs)
            validate_vpc_isolation(attrs)
            validate_distributed(attrs)
            validate_hyperparameters(attrs[:hyper_parameters])
          end

          def self.validate_algorithm(algo_spec)
            return unless algo_spec
            has_image, has_algorithm = algo_spec[:training_image], algo_spec[:algorithm_name]
            raise Dry::Struct::Error, 'Either training_image or algorithm_name must be specified' if !has_image && !has_algorithm
            raise Dry::Struct::Error, 'Cannot specify both training_image and algorithm_name' if has_image && has_algorithm
            algo_spec[:metric_definitions]&.each_with_index do |metric, i|
              Regexp.new(metric[:regex])
            rescue RegexpError => e
              raise Dry::Struct::Error, "Metric definition #{i}: Invalid regex '#{metric[:regex]}': #{e.message}"
            end
          end

          def self.validate_channels(input_data_config)
            return unless input_data_config
            names = input_data_config.map { |c| c[:channel_name] }
            raise Dry::Struct::Error, 'Input data channel names must be unique' if names.uniq.size != names.size
          end

          def self.validate_spot_config(attrs)
            return unless attrs[:enable_managed_spot_training]
            max_runtime = attrs.dig(:stopping_condition, :max_runtime_in_seconds)
            raise Dry::Struct::Error, 'Managed spot training max runtime cannot exceed 48 hours (172800 seconds)' if max_runtime.to_i > 172_800
          end

          def self.validate_vpc_isolation(attrs)
            raise Dry::Struct::Error, 'VPC configuration cannot be specified when network isolation is enabled' if attrs[:enable_network_isolation] && attrs[:vpc_config]
          end

          def self.validate_distributed(attrs)
            return unless attrs.dig(:resource_config, :instance_count).to_i > 1
            attrs[:input_data_config]&.each do |config|
              raise Dry::Struct::Error, 'Pipe input mode is not supported for distributed training (instance_count > 1)' if config[:input_mode] == 'Pipe'
            end
          end

          def self.validate_hyperparameters(params)
            params&.each { |key, value| raise Dry::Struct::Error, "Hyperparameter '#{key}' value exceeds maximum length of 2500 characters" if value.length > 2500 }
          end
        end

        module SageMakerCostCalculator
          COSTS = { 'ml.m4' => 0.20, 'ml.m5.large' => 0.115, 'ml.m5.xlarge' => 0.23, 'ml.m5.2xlarge' => 0.46, 'ml.c4' => 0.15, 'ml.c5' => 0.20,
                    'ml.p2.xlarge' => 0.90, 'ml.p3.2xlarge' => 3.06, 'ml.p3.8xlarge' => 12.24, 'ml.p3.16xlarge' => 24.48, 'ml.g4dn' => 1.20 }.freeze

          def self.instance_cost(type)
            COSTS.find { |k, _| type.start_with?(k) }&.last || 0.25
          end
        end
      end
    end
  end
end
