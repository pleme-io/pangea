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
  module Architectures
    module Examples
      # AI/ML platform architecture example
      module MlPlatform
        def ml_platform_architecture(name, attributes = {})
          platform_attrs = {
            environment: attributes[:environment] || 'production',
            domain: attributes[:domain] || "ml.#{name}.com",
            vpc_cidr: '10.3.0.0/16'
          }

          data_platform = create_data_platform(name, platform_attrs)
          inference_stream = create_inference_stream(name)
          ml_web_app = create_ml_web_app(name, platform_attrs)

          composite_ref = create_architecture_reference('ml_platform', name, platform_attrs)
          composite_ref.data_platform = data_platform
          composite_ref.inference_stream = inference_stream
          composite_ref.web_application = ml_web_app

          add_ml_extensions(composite_ref, name, data_platform)

          composite_ref
        end

        private

        def create_data_platform(name, platform_attrs)
          data_lake_architecture(
            :"#{name}_data_lake",
            data_lake_name: "#{name}-ml-data",
            environment: platform_attrs[:environment],
            vpc_cidr: platform_attrs[:vpc_cidr],
            data_sources: %w[s3 rds kinesis],
            real_time_processing: true,
            batch_processing: true,
            data_warehouse: 'redshift',
            machine_learning: true,
            raw_data_retention_days: 2555,
            processed_data_retention_days: 1095
          )
        end

        def create_inference_stream(name)
          streaming_data_architecture(
            :"#{name}_inference_stream",
            stream_name: "#{name}-inference-requests",
            stream_type: 'kinesis',
            shard_count: 20,
            retention_hours: 24,
            stream_processing_framework: 'kinesis-analytics',
            windowing_strategy: 'sliding',
            window_size_minutes: 1,
            output_destinations: %w[s3 dynamodb],
            error_handling: 'dlq'
          )
        end

        def create_ml_web_app(name, platform_attrs)
          web_application_architecture(
            :"#{name}_web",
            domain: platform_attrs[:domain],
            environment: platform_attrs[:environment],
            vpc_cidr: '10.4.0.0/16',
            high_availability: true,
            auto_scaling: { min: 2, max: 10 },
            database_engine: 'postgresql',
            s3_bucket_enabled: true,
            monitoring_enabled: true
          )
        end

        def add_ml_extensions(composite_ref, name, data_platform)
          composite_ref.extend do |arch_ref|
            arch_ref.ml_endpoints = build_ml_endpoints(name, data_platform)
            arch_ref.model_registry = { type: 'sagemaker_model_package_group', name: "#{name}-models", description: "Model registry for #{name} ML platform" }
          end
        end

        def build_ml_endpoints(name, data_platform)
          {
            model_training: {
              type: 'sagemaker_training_job', name: "#{name}-training",
              role_arn: 'arn:aws:iam::account:role/SageMakerRole',
              algorithm_specification: { training_image: '382416733822.dkr.ecr.us-east-1.amazonaws.com/xgboost:latest', training_input_mode: 'File' },
              input_data_config: [{ channel_name: 'training', data_source: { s3_data_source: { s3_data_type: 'S3Prefix', s3_uri: "s3://#{data_platform.storage[:processed_bucket].bucket}/training-data/", s3_data_distribution_type: 'FullyReplicated' } } }],
              output_data_config: { s3_output_path: "s3://#{data_platform.storage[:processed_bucket].bucket}/model-artifacts/" },
              resource_config: { instance_type: 'ml.m5.large', instance_count: 1, volume_size_in_gb: 30 }
            },
            inference_endpoint: { type: 'sagemaker_endpoint', name: "#{name}-inference", endpoint_config_name: "#{name}-endpoint-config", initial_instance_count: 2, instance_type: 'ml.t2.medium' }
          }
        end
      end
    end
  end
end
