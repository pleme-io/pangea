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


require 'pangea/resources/base'
require 'pangea/resources/aws_sagemaker_endpoint_configuration/types'
require 'pangea/resource_registry'
require_relative 'reference_attributes'

module Pangea
  module Resources
    module AWS
      # SageMaker Endpoint Configuration resource for defining model serving infrastructure
      # 
      # An endpoint configuration specifies the ML compute instances and models to deploy 
      # for real-time inference. It supports multi-variant deployments, A/B testing,
      # serverless inference, and async inference capabilities.
      #
      # @example Basic real-time endpoint configuration
      #   aws_sagemaker_endpoint_configuration(:fraud_config, {
      #     name: "fraud-detection-config-v1",
      #     production_variants: [
      #       {
      #         variant_name: "primary",
      #         model_name: fraud_model_ref.model_name,
      #         initial_instance_count: 2,
      #         instance_type: "ml.m5.large",
      #         initial_variant_weight: 1.0
      #       }
      #     ]
      #   })
      #
      # @example Multi-variant A/B testing configuration
      #   aws_sagemaker_endpoint_configuration(:ab_test_config, {
      #     name: "fraud-ab-test-config",
      #     production_variants: [
      #       {
      #         variant_name: "model-a",
      #         model_name: model_a_ref.model_name,
      #         initial_instance_count: 2,
      #         instance_type: "ml.m5.large", 
      #         initial_variant_weight: 0.7
      #       },
      #       {
      #         variant_name: "model-b",
      #         model_name: model_b_ref.model_name,
      #         initial_instance_count: 1,
      #         instance_type: "ml.m5.large",
      #         initial_variant_weight: 0.3
      #       }
      #     ],
      #     data_capture_config: {
      #       enable_capture: true,
      #       initial_sampling_percentage: 100,
      #       destination_s3_uri: "s3://#{monitoring_bucket_ref.bucket}/data-capture/",
      #       kms_key_id: kms_key_ref.arn,
      #       capture_options: [
      #         { capture_mode: "Input" },
      #         { capture_mode: "Output" }
      #       ]
      #     }
      #   })
      #
      # @example High-performance GPU configuration with data capture
      #   aws_sagemaker_endpoint_configuration(:gpu_inference_config, {
      #     name: "gpu-model-config",
      #     production_variants: [
      #       {
      #         variant_name: "gpu-variant",
      #         model_name: gpu_model_ref.model_name,
      #         initial_instance_count: 2,
      #         instance_type: "ml.p3.2xlarge",
      #         initial_variant_weight: 1.0,
      #         accelerator_type: "ml.eia2.medium",
      #         core_dump_config: {
      #           destination_s3_uri: "s3://#{debug_bucket_ref.bucket}/core-dumps/",
      #           kms_key_id: kms_key_ref.arn
      #         }
      #       }
      #     ],
      #     kms_key_id: kms_key_ref.arn,
      #     data_capture_config: {
      #       enable_capture: true,
      #       initial_sampling_percentage: 20,
      #       destination_s3_uri: "s3://#{monitoring_bucket_ref.bucket}/inference-data/",
      #       kms_key_id: kms_key_ref.arn,
      #       capture_options: [
      #         { capture_mode: "Input" },
      #         { capture_mode: "Output" }
      #       ],
      #       capture_content_type_header: {
      #         json_content_types: ["application/json"],
      #         csv_content_types: ["text/csv"]
      #       }
      #     }
      #   })
      #
      # @example Serverless inference configuration
      #   aws_sagemaker_endpoint_configuration(:serverless_config, {
      #     name: "serverless-inference-config",
      #     production_variants: [
      #       {
      #         variant_name: "serverless",
      #         model_name: serverless_model_ref.model_name,
      #         instance_type: "ml.m5.large",
      #         serverless_config: {
      #           memory_size_in_mb: 2048,
      #           max_concurrency: 10
      #         }
      #       }
      #     ]
      #   })
      #
      # @example Async inference configuration
      #   aws_sagemaker_endpoint_configuration(:async_config, {
      #     name: "async-batch-inference-config",
      #     production_variants: [
      #       {
      #         variant_name: "async-variant",
      #         model_name: batch_model_ref.model_name,
      #         initial_instance_count: 1,
      #         instance_type: "ml.m5.2xlarge"
      #       }
      #     ],
      #     async_inference_config: {
      #       output_config: {
      #         s3_output_path: "s3://#{results_bucket_ref.bucket}/async-results/",
      #         kms_key_id: kms_key_ref.arn,
      #         notification_config: {
      #           success_topic: success_sns_ref.arn,
      #           error_topic: error_sns_ref.arn,
      #           include_inference_response_in: ["SUCCESS_NOTIFICATION_TOPIC"]
      #         },
      #         s3_failure_path: "s3://#{results_bucket_ref.bucket}/async-failures/"
      #       },
      #       client_config: {
      #         max_concurrent_invocations_per_instance: 4
      #       }
      #     },
      #     tags: {
      #       InferenceType: "async",
      #       Environment: "production"
      #     }
      #   })
      class SageMakerEndpointConfiguration < Base
        def self.resource_type
          'aws_sagemaker_endpoint_configuration'
        end
        
        def self.attribute_struct
          Types::SageMakerEndpointConfigurationAttributes
        end
      end
      
      # Resource function for aws_sagemaker_endpoint_configuration
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] The resource attributes
      # @return [ResourceReference] Reference to the created resource
      def aws_sagemaker_endpoint_configuration(name, attributes)
        resource = SageMakerEndpointConfiguration.new(
          name: name,
          attributes: attributes
        )

        add_resource(resource)

        # Return resource reference with computed attributes
        ResourceReference.new(
          name: name,
          type: :aws_sagemaker_endpoint_configuration,
          attributes: SageMakerEndpointConfigurationReferenceAttributes.build(name, attributes)
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)