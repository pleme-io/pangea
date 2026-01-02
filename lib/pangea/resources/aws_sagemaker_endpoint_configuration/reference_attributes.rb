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

module Pangea
  module Resources
    module AWS
      # Builds reference attributes for SageMaker Endpoint Configuration resources
      module SageMakerEndpointConfigurationReferenceAttributes
        module_function

        # Builds the complete attributes hash for ResourceReference
        # @param name [Symbol] The resource name
        # @param attributes [Hash] The resource attributes
        # @return [Hash] The reference attributes
        def build(name, attributes)
          {
            # Direct attributes
            id: "${aws_sagemaker_endpoint_configuration.#{name}.id}",
            arn: "${aws_sagemaker_endpoint_configuration.#{name}.arn}",
            name: "${aws_sagemaker_endpoint_configuration.#{name}.name}",

            # Computed attributes
            creation_time: "${aws_sagemaker_endpoint_configuration.#{name}.creation_time}",

            # Helper attributes for integration
            config_name: "${aws_sagemaker_endpoint_configuration.#{name}.name}",
            variant_count: production_variants(attributes)&.size || 0,
            total_instance_count: total_instance_count(attributes),

            # Configuration type classification
            is_serverless: serverless?(attributes),
            is_multi_variant: multi_variant?(attributes),
            has_gpu_instances: has_gpu_instances?(attributes),
            has_inference_optimized: has_inference_optimized?(attributes),
            has_accelerators: has_accelerators?(attributes),

            # Feature flags
            data_capture_enabled: attributes.dig(:data_capture_config, :enable_capture) == true,
            async_inference_enabled: !attributes[:async_inference_config].nil?,
            kms_encrypted: !attributes[:kms_key_id].nil?,

            # Instance type summary
            instance_types: instance_types(attributes),
            primary_instance_type: production_variants(attributes)&.first&.dig(:instance_type),

            # Capacity information
            min_capacity: min_capacity(attributes),
            max_capacity: max_capacity(attributes),

            # Cost estimation
            estimated_monthly_cost: compute_estimated_monthly_cost(attributes)
          }
        end

        # Extracts production variants from attributes
        def production_variants(attributes)
          attributes[:production_variants]
        end

        # Calculates total instance count across all variants
        def total_instance_count(attributes)
          production_variants(attributes)&.sum { |v| v[:initial_instance_count].to_i } || 0
        end

        # Checks if all variants are serverless
        def serverless?(attributes)
          variants = production_variants(attributes)
          return false if variants.nil? || variants.empty?

          variants.all? { |v| v[:serverless_config] }
        end

        # Checks if configuration has multiple variants
        def multi_variant?(attributes)
          (production_variants(attributes)&.size || 0) > 1
        end

        # Checks if any variant uses GPU instances
        def has_gpu_instances?(attributes)
          production_variants(attributes)&.any? { |v| v[:instance_type]&.match?(/ml\.(p|g)/) } || false
        end

        # Checks if any variant uses inference-optimized instances
        def has_inference_optimized?(attributes)
          production_variants(attributes)&.any? { |v| v[:instance_type]&.start_with?('ml.inf') } || false
        end

        # Checks if any variant has accelerators
        def has_accelerators?(attributes)
          production_variants(attributes)&.any? { |v| v[:accelerator_type] } || false
        end

        # Extracts unique instance types from variants
        def instance_types(attributes)
          production_variants(attributes)&.map { |v| v[:instance_type] }&.uniq || []
        end

        # Calculates minimum capacity across variants
        def min_capacity(attributes)
          production_variants(attributes)&.map { |v| v[:initial_instance_count] }&.compact&.min || 0
        end

        # Calculates maximum capacity across variants
        def max_capacity(attributes)
          production_variants(attributes)&.map { |v| v[:initial_instance_count] }&.compact&.max || 0
        end

        # Computes estimated monthly cost using Types struct
        def compute_estimated_monthly_cost(attributes)
          config_attrs = Types::SageMakerEndpointConfigurationAttributes.new(attributes)
          config_attrs.estimated_monthly_cost
        rescue StandardError
          0.0
        end
      end
    end
  end
end
