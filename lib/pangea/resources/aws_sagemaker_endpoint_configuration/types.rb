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
        # SageMaker Endpoint Configuration instance types for inference
        SageMakerInferenceInstanceType = String.enum(
          # General purpose
          'ml.t2.medium', 'ml.t2.large', 'ml.t2.xlarge', 'ml.t2.2xlarge',
          'ml.m4.xlarge', 'ml.m4.2xlarge', 'ml.m4.4xlarge', 'ml.m4.10xlarge', 'ml.m4.16xlarge',
          'ml.m5.large', 'ml.m5.xlarge', 'ml.m5.2xlarge', 'ml.m5.4xlarge', 'ml.m5.12xlarge', 'ml.m5.24xlarge',
          'ml.m5d.large', 'ml.m5d.xlarge', 'ml.m5d.2xlarge', 'ml.m5d.4xlarge', 'ml.m5d.12xlarge', 'ml.m5d.24xlarge',
          # Compute optimized
          'ml.c4.large', 'ml.c4.xlarge', 'ml.c4.2xlarge', 'ml.c4.4xlarge', 'ml.c4.8xlarge',
          'ml.c5.large', 'ml.c5.xlarge', 'ml.c5.2xlarge', 'ml.c5.4xlarge', 'ml.c5.9xlarge', 'ml.c5.18xlarge',
          'ml.c5d.large', 'ml.c5d.xlarge', 'ml.c5d.2xlarge', 'ml.c5d.4xlarge', 'ml.c5d.9xlarge', 'ml.c5d.18xlarge',
          # Memory optimized  
          'ml.r4.large', 'ml.r4.xlarge', 'ml.r4.2xlarge', 'ml.r4.4xlarge', 'ml.r4.8xlarge', 'ml.r4.16xlarge',
          'ml.r5.large', 'ml.r5.xlarge', 'ml.r5.2xlarge', 'ml.r5.4xlarge', 'ml.r5.12xlarge', 'ml.r5.24xlarge',
          'ml.r5d.large', 'ml.r5d.xlarge', 'ml.r5d.2xlarge', 'ml.r5d.4xlarge', 'ml.r5d.12xlarge', 'ml.r5d.24xlarge',
          # GPU instances
          'ml.p2.xlarge', 'ml.p2.8xlarge', 'ml.p2.16xlarge',
          'ml.p3.2xlarge', 'ml.p3.8xlarge', 'ml.p3.16xlarge',
          'ml.g4dn.xlarge', 'ml.g4dn.2xlarge', 'ml.g4dn.4xlarge', 'ml.g4dn.8xlarge', 'ml.g4dn.12xlarge', 'ml.g4dn.16xlarge',
          # Inference optimized
          'ml.inf1.xlarge', 'ml.inf1.2xlarge', 'ml.inf1.6xlarge', 'ml.inf1.24xlarge'
        )
        
        # SageMaker Production Variant configuration
        SageMakerProductionVariant = Hash.schema(
          variant_name: String.constrained(
            min_size: 1,
            max_size: 63,
            format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/
          ),
          model_name: String,
          initial_instance_count: Integer.constrained(gteq: 1, lteq: 1000),
          instance_type: SageMakerInferenceInstanceType,
          initial_variant_weight?: Float.constrained(gteq: 0.0, lteq: 1.0).default(1.0),
          accelerator_type?: String.enum(
            'ml.eia1.medium', 'ml.eia1.large', 'ml.eia1.xlarge',
            'ml.eia2.medium', 'ml.eia2.large', 'ml.eia2.xlarge'
          ).optional,
          core_dump_config?: Hash.schema(
            destination_s3_uri: String.constrained(format: /\As3:\/\//),
            kms_key_id?: String.optional
          ).optional,
          serverless_config?: Hash.schema(
            memory_size_in_mb: Integer.constrained(gteq: 1024, lteq: 6144),
            max_concurrency: Integer.constrained(gteq: 1, lteq: 200)
          ).optional
        ).constructor { |value|
          # Validate serverless vs instance configuration
          if value[:serverless_config] && value[:instance_type]
            unless %w[ml.m5.large ml.m5.xlarge ml.m5.2xlarge ml.m5.4xlarge ml.m5.12xlarge ml.m5.24xlarge].include?(value[:instance_type])
              raise Dry::Types::ConstraintError, "Serverless inference only supports specific M5 instance types"
            end
          end
          
          # Validate accelerator compatibility
          if value[:accelerator_type] && value[:instance_type]
            incompatible_types = %w[ml.t2 ml.t3 ml.m4 ml.c4 ml.c5]
            if incompatible_types.any? { |type| value[:instance_type].start_with?(type) }
              raise Dry::Types::ConstraintError, "Accelerator type #{value[:accelerator_type]} not compatible with #{value[:instance_type]}"
            end
          end
          
          value
        }
        
        # SageMaker Endpoint Configuration data capture configuration
        SageMakerDataCaptureConfig = Hash.schema(
          enable_capture: Bool.default(false),
          initial_sampling_percentage: Integer.constrained(gteq: 0, lteq: 100),
          destination_s3_uri: String.constrained(format: /\As3:\/\//),
          kms_key_id?: String.optional,
          capture_options: Array.of(
            Hash.schema(
              capture_mode: String.enum('Input', 'Output')
            )
          ).constrained(min_size: 1),
          capture_content_type_header?: Hash.schema(
            csv_content_types?: Array.of(String).optional,
            json_content_types?: Array.of(String).optional
          ).optional
        )
        
        # SageMaker Endpoint Configuration attributes with comprehensive validation
        class SageMakerEndpointConfigurationAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 63,
            format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/
          )
          attribute :production_variants, Resources::Types::Array.of(SageMakerProductionVariant).constrained(min_size: 1, max_size: 10)
          
          # Optional attributes
          attribute :data_capture_config, SageMakerDataCaptureConfig.optional
          attribute :kms_key_id, Resources::Types::String.optional
          attribute :async_inference_config, Resources::Types::Hash.schema(
            output_config: Hash.schema(
              s3_output_path: String.constrained(format: /\As3:\/\//),
              notification_config?: Hash.schema(
                success_topic?: String.optional,
                error_topic?: String.optional,
                include_inference_response_in?: Array.of(String.enum('SUCCESS_NOTIFICATION_TOPIC', 'ERROR_NOTIFICATION_TOPIC')).optional
              ).optional,
              s3_failure_path?: String.optional,
              kms_key_id?: String.optional
            ),
            client_config?: Hash.schema(
              max_concurrent_invocations_per_instance?: Integer.constrained(gteq: 1, lteq: 1000).optional
            ).optional
          ).optional
          attribute :tags, Resources::Types::AwsTags
          
          # Custom validation for SageMaker Endpoint Configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate production variant names are unique
            if attrs[:production_variants]
              variant_names = attrs[:production_variants].map { |v| v[:variant_name] }
              if variant_names.uniq.size != variant_names.size
                raise Dry::Struct::Error, "Production variant names must be unique"
              end
            end
            
            # Validate production variant weights sum to 1.0 (or all default to 1.0)
            if attrs[:production_variants]
              weights = attrs[:production_variants].map { |v| v[:initial_variant_weight] || 1.0 }
              if attrs[:production_variants].size > 1
                weight_sum = weights.sum
                unless (weight_sum - 1.0).abs < 0.001 # Allow for floating point precision
                  raise Dry::Struct::Error, "Production variant weights must sum to 1.0, got #{weight_sum}"
                end
              end
            end
            
            # Validate serverless vs real-time configuration consistency
            if attrs[:production_variants]
              serverless_count = attrs[:production_variants].count { |v| v[:serverless_config] }
              realtime_count = attrs[:production_variants].size - serverless_count
              
              if serverless_count > 0 && realtime_count > 0
                raise Dry::Struct::Error, "Cannot mix serverless and real-time inference in the same endpoint configuration"
              end
            end
            
            # Validate data capture configuration
            if attrs[:data_capture_config] && attrs[:data_capture_config][:enable_capture]
              capture_config = attrs[:data_capture_config]
              unless capture_config[:destination_s3_uri]
                raise Dry::Struct::Error, "destination_s3_uri is required when data capture is enabled"
              end
              
              unless capture_config[:capture_options] && capture_config[:capture_options].any?
                raise Dry::Struct::Error, "At least one capture option (Input/Output) must be specified"
              end
            end
            
            # Validate async inference configuration
            if attrs[:async_inference_config]
              async_config = attrs[:async_inference_config]
              
              # Validate async inference is only for supported instance types
              if attrs[:production_variants]
                attrs[:production_variants].each do |variant|
                  if variant[:serverless_config]
                    raise Dry::Struct::Error, "Async inference is not supported with serverless inference"
                  end
                end
              end
            end
            
            # Validate KMS key format
            if attrs[:kms_key_id]
              unless attrs[:kms_key_id] =~ /\A(arn:aws:kms:|alias\/|[a-f0-9-]{36})/
                raise Dry::Struct::Error, "kms_key_id must be a valid KMS key ARN, alias, or key ID"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def estimated_monthly_cost
            variant_costs = production_variants.sum do |variant|
              get_variant_monthly_cost(variant)
            end
            
            storage_cost = data_capture_config ? get_data_capture_cost : 0.0
            async_cost = async_inference_config ? 5.0 : 0.0 # Async inference overhead
            
            variant_costs + storage_cost + async_cost
          end
          
          def get_variant_monthly_cost(variant)
            if variant[:serverless_config]
              # Serverless pricing is pay-per-request
              return 50.0 # Estimated based on moderate usage
            else
              instance_cost = get_instance_cost_per_hour(variant[:instance_type])
              accelerator_cost = get_accelerator_cost(variant[:accelerator_type])
              
              (instance_cost + accelerator_cost) * variant[:initial_instance_count] * 24 * 30
            end
          end
          
          def get_instance_cost_per_hour(instance_type)
            # Simplified pricing lookup
            case instance_type
            when /^ml\.t2/ then 0.065
            when /^ml\.m4/ then 0.20
            when /^ml\.m5\.large/ then 0.115
            when /^ml\.m5\.xlarge/ then 0.23
            when /^ml\.m5\.2xlarge/ then 0.46
            when /^ml\.c5\.large/ then 0.102
            when /^ml\.c5\.xlarge/ then 0.204
            when /^ml\.r5\.large/ then 0.145
            when /^ml\.r5\.xlarge/ then 0.29
            when /^ml\.p3\.2xlarge/ then 3.825
            when /^ml\.g4dn\.xlarge/ then 0.736
            when /^ml\.inf1\.xlarge/ then 0.368
            else 0.20
            end
          end
          
          def get_accelerator_cost(accelerator_type)
            return 0.0 unless accelerator_type
            
            case accelerator_type
            when 'ml.eia1.medium' then 0.13
            when 'ml.eia1.large' then 0.26
            when 'ml.eia1.xlarge' then 0.52
            when 'ml.eia2.medium' then 0.14
            when 'ml.eia2.large' then 0.28
            when 'ml.eia2.xlarge' then 0.56
            else 0.0
            end
          end
          
          def get_data_capture_cost
            return 0.0 unless data_capture_config&.dig(:enable_capture)
            
            # Estimate based on sampling percentage and storage
            sampling = data_capture_config[:initial_sampling_percentage] / 100.0
            estimated_requests = 100_000 # Per month
            captured_requests = estimated_requests * sampling
            
            # S3 storage cost for captured data
            captured_requests * 0.001 # $0.001 per captured request (rough estimate)
          end
          
          def is_serverless_configuration?
            production_variants.all? { |v| v[:serverless_config] }
          end
          
          def is_multi_variant_configuration?
            production_variants.size > 1
          end
          
          def has_gpu_instances?
            production_variants.any? { |v| v[:instance_type].match?(/ml\.(p|g)/) }
          end
          
          def has_inference_optimized_instances?
            production_variants.any? { |v| v[:instance_type].start_with?('ml.inf') }
          end
          
          def has_accelerators?
            production_variants.any? { |v| v[:accelerator_type] }
          end
          
          def has_data_capture?
            data_capture_config&.dig(:enable_capture) == true
          end
          
          def has_async_inference?
            !async_inference_config.nil?
          end
          
          def uses_kms_encryption?
            !kms_key_id.nil?
          end
          
          def total_instance_count
            production_variants.sum { |v| v[:initial_instance_count] }
          end
          
          def variant_count
            production_variants.size
          end
          
          # Configuration analysis
          def inference_configuration
            {
              type: is_serverless_configuration? ? 'serverless' : 'real-time',
              variant_count: variant_count,
              total_instances: total_instance_count,
              has_gpu: has_gpu_instances?,
              has_accelerators: has_accelerators?,
              multi_variant: is_multi_variant_configuration?,
              data_capture_enabled: has_data_capture?,
              async_inference_enabled: has_async_inference?
            }
          end
          
          # Security and compliance assessment
          def security_score
            score = 0
            score += 20 if uses_kms_encryption?
            score += 15 if has_data_capture? && data_capture_config[:kms_key_id]
            score += 10 if has_async_inference? && async_inference_config.dig(:output_config, :kms_key_id)
            score += 10 if production_variants.all? { |v| v[:core_dump_config]&.dig(:kms_key_id) }
            score += 15 if has_data_capture? && data_capture_config[:capture_options].size == 2 # Both input and output
            score += 10 if is_serverless_configuration? # Serverless has better isolation
            
            [score, 100].min
          end
          
          def compliance_status
            issues = []
            issues << "No KMS encryption for endpoint configuration" unless uses_kms_encryption?
            issues << "Data capture enabled but not encrypted" if has_data_capture? && !data_capture_config[:kms_key_id]
            issues << "Async inference output not encrypted" if has_async_inference? && !async_inference_config.dig(:output_config, :kms_key_id)
            issues << "Core dump configuration missing KMS encryption" if production_variants.any? { |v| v[:core_dump_config] && !v[:core_dump_config][:kms_key_id] }
            
            {
              status: issues.empty? ? 'compliant' : 'needs_attention',
              issues: issues
            }
          end
        end
      end
    end
  end
end