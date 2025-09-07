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
require 'pangea/resources/aws_sagemaker_model/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # SageMaker Model resource for defining ML models for inference
      # 
      # A model in SageMaker defines the inference code and model artifacts needed 
      # to deploy machine learning models to endpoints. Models can be single-container
      # or multi-container for ensemble inference scenarios.
      #
      # @example Basic single-container model
      #   aws_sagemaker_model(:fraud_detection_model, {
      #     model_name: "fraud-detection-v1",
      #     execution_role_arn: model_role_ref.arn,
      #     primary_container: {
      #       image: "763104351884.dkr.ecr.us-east-1.amazonaws.com/sklearn-inference:0.23-1-cpu-py3",
      #       model_data_url: "s3://#{model_bucket_ref.bucket}/fraud-model/model.tar.gz"
      #     }
      #   })
      #
      # @example Multi-container ensemble model
      #   aws_sagemaker_model(:ensemble_model, {
      #     model_name: "fraud-ensemble-v1", 
      #     execution_role_arn: model_role_ref.arn,
      #     containers: [
      #       {
      #         image: "763104351884.dkr.ecr.us-east-1.amazonaws.com/xgboost:1.3-1-cpu-py3",
      #         model_data_url: "s3://#{model_bucket_ref.bucket}/xgboost-model/model.tar.gz",
      #         container_hostname: "xgboost-container",
      #         environment: {
      #           MODEL_NAME: "xgboost",
      #           SAGEMAKER_PROGRAM: "inference.py"
      #         }
      #       },
      #       {
      #         image: "763104351884.dkr.ecr.us-east-1.amazonaws.com/pytorch-inference:1.8.1-cpu-py3",
      #         model_data_url: "s3://#{model_bucket_ref.bucket}/pytorch-model/model.tar.gz", 
      #         container_hostname: "pytorch-container",
      #         environment: {
      #           MODEL_NAME: "pytorch",
      #           SAGEMAKER_PROGRAM: "predict.py"
      #         }
      #       }
      #     ],
      #     inference_execution_config: {
      #       mode: "Direct"
      #     }
      #   })
      #
      # @example Secure model with VPC configuration
      #   aws_sagemaker_model(:secure_model, {
      #     model_name: "secure-fraud-model",
      #     execution_role_arn: model_role_ref.arn,
      #     primary_container: {
      #       image: "#{account_id}.dkr.ecr.#{region}.amazonaws.com/custom-fraud-detector:latest",
      #       model_data_url: "s3://#{secure_bucket_ref.bucket}/encrypted-model/model.tar.gz",
      #       environment: {
      #         MODEL_SERVER_TIMEOUT: "120",
      #         MODEL_SERVER_WORKERS: "4",
      #         SAGEMAKER_PROGRAM: "inference.py",
      #         SAGEMAKER_SUBMIT_DIRECTORY: "/opt/ml/code"
      #       },
      #       image_config: {
      #         repository_access_mode: "Vpc",
      #         repository_auth_config: {
      #           repository_credentials_provider_arn: ecr_credentials_ref.arn
      #         }
      #       }
      #     },
      #     vpc_config: {
      #       security_group_ids: [model_sg_ref.id],
      #       subnets: [private_subnet_a_ref.id, private_subnet_b_ref.id]
      #     },
      #     enable_network_isolation: true,
      #     tags: {
      #       Environment: "production",
      #       ModelType: "fraud-detection",
      #       Security: "high",
      #       Compliance: "pci-dss"
      #     }
      #   })
      #
      # @example Multi-model endpoint model
      #   aws_sagemaker_model(:multi_model, {
      #     model_name: "multi-model-endpoint",
      #     execution_role_arn: model_role_ref.arn,
      #     primary_container: {
      #       image: "763104351884.dkr.ecr.us-east-1.amazonaws.com/sklearn-inference:0.23-1-cpu-py3",
      #       model_data_url: "s3://#{model_bucket_ref.bucket}/multi-model/",
      #       multi_model_config: {
      #         model_cache_setting: "Enabled"
      #       },
      #       environment: {
      #         SAGEMAKER_MULTI_MODEL: "true",
      #         SAGEMAKER_PROGRAM: "inference.py"
      #       }
      #     }
      #   })
      class SageMakerModel < Base
        def self.resource_type
          'aws_sagemaker_model'
        end
        
        def self.attribute_struct
          Types::SageMakerModelAttributes
        end
      end
      
      # Resource function for aws_sagemaker_model
      # 
      # @param name [Symbol] The resource name
      # @param attributes [Hash] The resource attributes
      # @return [ResourceReference] Reference to the created resource
      def aws_sagemaker_model(name, attributes)
        resource = SageMakerModel.new(
          name: name,
          attributes: attributes
        )
        
        add_resource(resource)
        
        # Return resource reference with computed attributes
        ResourceReference.new(
          name: name,
          type: :aws_sagemaker_model,
          attributes: {
            # Direct attributes
            id: "${aws_sagemaker_model.#{name}.id}",
            arn: "${aws_sagemaker_model.#{name}.arn}",
            name: "${aws_sagemaker_model.#{name}.name}",
            model_name: "${aws_sagemaker_model.#{name}.name}",
            execution_role_arn: "${aws_sagemaker_model.#{name}.execution_role_arn}",
            
            # Computed attributes 
            creation_time: "${aws_sagemaker_model.#{name}.creation_time}",
            
            # Helper attributes for integration
            is_multi_container: attributes[:containers]&.size.to_i > 1,
            container_count: attributes[:containers]&.size || (attributes[:primary_container] ? 1 : 0),
            has_vpc_config: !attributes[:vpc_config].nil?,
            network_isolated: attributes[:enable_network_isolation] == true,
            uses_multi_model_endpoint: attributes.dig(:primary_container, :multi_model_config, :model_cache_setting) == 'Enabled',
            
            # Model type classification
            model_type: attributes[:containers]&.size.to_i > 1 ? 'multi-container' : 'single-container',
            inference_mode: attributes.dig(:inference_execution_config, :mode) || (attributes[:containers]&.size.to_i > 1 ? 'Serial' : 'Direct'),
            
            # Security attributes
            uses_custom_images: begin
              all_containers = []
              all_containers << attributes[:primary_container] if attributes[:primary_container]
              all_containers.concat(attributes[:containers] || [])
              all_containers.any? { |c| !c[:image].include?('763104351884.dkr.ecr') }
            end,
            
            uses_model_packages: begin
              all_containers = []
              all_containers << attributes[:primary_container] if attributes[:primary_container]
              all_containers.concat(attributes[:containers] || [])
              all_containers.any? { |c| c[:model_package_name] }
            end
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)