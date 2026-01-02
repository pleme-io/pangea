# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/types'
require_relative 'variant_types'

module Pangea
  module Resources
    module AWS
      module Types
        # SageMaker Endpoint Configuration attributes with comprehensive validation
        class SageMakerEndpointConfigurationAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :name, Resources::Types::String.constrained(min_size: 1, max_size: 63, format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/)
          attribute :production_variants, Resources::Types::Array.of(SageMakerProductionVariant).constrained(min_size: 1, max_size: 10)
          attribute :data_capture_config, SageMakerDataCaptureConfig.optional
          attribute :kms_key_id, Resources::Types::String.optional
          attribute :async_inference_config, Resources::Types::Hash.schema(
            output_config: Hash.schema(
              s3_output_path: String.constrained(format: /\As3:\/\//),
              notification_config?: Hash.schema(success_topic?: String.optional, error_topic?: String.optional, include_inference_response_in?: Array.of(String.enum('SUCCESS_NOTIFICATION_TOPIC', 'ERROR_NOTIFICATION_TOPIC')).optional).optional,
              s3_failure_path?: String.optional, kms_key_id?: String.optional
            ),
            client_config?: Hash.schema(max_concurrent_invocations_per_instance?: Integer.constrained(gteq: 1, lteq: 1000).optional).optional
          ).optional
          attribute :tags, Resources::Types::AwsTags

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            validate_variants!(attrs)
            validate_data_capture!(attrs)
            validate_async_inference!(attrs)
            validate_kms_key!(attrs)
            super(attrs)
          end

          def self.validate_variants!(attrs)
            return unless attrs[:production_variants]

            variant_names = attrs[:production_variants].map { |v| v[:variant_name] }
            raise Dry::Struct::Error, 'Production variant names must be unique' if variant_names.uniq.size != variant_names.size

            if attrs[:production_variants].size > 1
              weights = attrs[:production_variants].map { |v| v[:initial_variant_weight] || 1.0 }
              raise Dry::Struct::Error, "Production variant weights must sum to 1.0, got #{weights.sum}" unless (weights.sum - 1.0).abs < 0.001
            end

            serverless_count = attrs[:production_variants].count { |v| v[:serverless_config] }
            realtime_count = attrs[:production_variants].size - serverless_count
            raise Dry::Struct::Error, 'Cannot mix serverless and real-time inference in the same endpoint configuration' if serverless_count.positive? && realtime_count.positive?
          end

          def self.validate_data_capture!(attrs)
            return unless attrs[:data_capture_config]&.dig(:enable_capture)

            capture_config = attrs[:data_capture_config]
            raise Dry::Struct::Error, 'destination_s3_uri is required when data capture is enabled' unless capture_config[:destination_s3_uri]
            raise Dry::Struct::Error, 'At least one capture option (Input/Output) must be specified' unless capture_config[:capture_options]&.any?
          end

          def self.validate_async_inference!(attrs)
            return unless attrs[:async_inference_config] && attrs[:production_variants]

            attrs[:production_variants].each do |variant|
              raise Dry::Struct::Error, 'Async inference is not supported with serverless inference' if variant[:serverless_config]
            end
          end

          def self.validate_kms_key!(attrs)
            return unless attrs[:kms_key_id]
            raise Dry::Struct::Error, 'kms_key_id must be a valid KMS key ARN, alias, or key ID' unless attrs[:kms_key_id] =~ /\A(arn:aws:kms:|alias\/|[a-f0-9-]{36})/
          end

          def estimated_monthly_cost
            variant_costs = production_variants.sum { |variant| get_variant_monthly_cost(variant) }
            storage_cost = data_capture_config ? get_data_capture_cost : 0.0
            async_cost = async_inference_config ? 5.0 : 0.0
            variant_costs + storage_cost + async_cost
          end

          def get_variant_monthly_cost(variant)
            return 50.0 if variant[:serverless_config]

            instance_cost = get_instance_cost_per_hour(variant[:instance_type])
            accelerator_cost = get_accelerator_cost(variant[:accelerator_type])
            (instance_cost + accelerator_cost) * variant[:initial_instance_count] * 24 * 30
          end

          def get_instance_cost_per_hour(instance_type)
            case instance_type
            when /^ml\.t2/ then 0.065
            when /^ml\.m5\.large/ then 0.115
            when /^ml\.m5\.xlarge/ then 0.23
            when /^ml\.c5\.large/ then 0.102
            when /^ml\.p3\.2xlarge/ then 3.825
            when /^ml\.g4dn\.xlarge/ then 0.736
            when /^ml\.inf1\.xlarge/ then 0.368
            else 0.20
            end
          end

          def get_accelerator_cost(accelerator_type)
            return 0.0 unless accelerator_type

            { 'ml.eia1.medium' => 0.13, 'ml.eia1.large' => 0.26, 'ml.eia1.xlarge' => 0.52, 'ml.eia2.medium' => 0.14, 'ml.eia2.large' => 0.28, 'ml.eia2.xlarge' => 0.56 }[accelerator_type] || 0.0
          end

          def get_data_capture_cost
            return 0.0 unless data_capture_config&.dig(:enable_capture)

            sampling = data_capture_config[:initial_sampling_percentage] / 100.0
            100_000 * sampling * 0.001
          end

          def is_serverless_configuration? = production_variants.all? { |v| v[:serverless_config] }
          def is_multi_variant_configuration? = production_variants.size > 1
          def has_gpu_instances? = production_variants.any? { |v| v[:instance_type].match?(/ml\.(p|g)/) }
          def has_inference_optimized_instances? = production_variants.any? { |v| v[:instance_type].start_with?('ml.inf') }
          def has_accelerators? = production_variants.any? { |v| v[:accelerator_type] }
          def has_data_capture? = data_capture_config&.dig(:enable_capture) == true
          def has_async_inference? = !async_inference_config.nil?
          def uses_kms_encryption? = !kms_key_id.nil?
          def total_instance_count = production_variants.sum { |v| v[:initial_instance_count] }
          def variant_count = production_variants.size

          def inference_configuration
            { type: is_serverless_configuration? ? 'serverless' : 'real-time', variant_count: variant_count, total_instances: total_instance_count, has_gpu: has_gpu_instances?, has_accelerators: has_accelerators?, multi_variant: is_multi_variant_configuration?, data_capture_enabled: has_data_capture?, async_inference_enabled: has_async_inference? }
          end

          def security_score
            score = 0
            score += 20 if uses_kms_encryption?
            score += 15 if has_data_capture? && data_capture_config[:kms_key_id]
            score += 10 if has_async_inference? && async_inference_config.dig(:output_config, :kms_key_id)
            score += 10 if production_variants.all? { |v| v[:core_dump_config]&.dig(:kms_key_id) }
            score += 15 if has_data_capture? && data_capture_config[:capture_options].size == 2
            score += 10 if is_serverless_configuration?
            [score, 100].min
          end

          def compliance_status
            issues = []
            issues << 'No KMS encryption for endpoint configuration' unless uses_kms_encryption?
            issues << 'Data capture enabled but not encrypted' if has_data_capture? && !data_capture_config[:kms_key_id]
            issues << 'Async inference output not encrypted' if has_async_inference? && !async_inference_config.dig(:output_config, :kms_key_id)
            issues << 'Core dump configuration missing KMS encryption' if production_variants.any? { |v| v[:core_dump_config] && !v[:core_dump_config][:kms_key_id] }
            { status: issues.empty? ? 'compliant' : 'needs_attention', issues: issues }
          end
        end
      end
    end
  end
end
