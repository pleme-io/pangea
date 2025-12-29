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
  module Components
    module SustainableMLTraining
      # SageMaker training job and experiment tracking
      module Training
        def create_training_job(input, role, s3_bucket, fsx_filesystem)
          aws_sagemaker_training_job(:"#{input.name}-training", {
            training_job_name: "#{input.name}-#{Time.now.strftime('%Y%m%d-%H%M%S')}",
            role_arn: role.arn,
            algorithm_specification: build_algorithm_specification(input, fsx_filesystem),
            hyper_parameters: generate_hyperparameters(input),
            input_data_config: build_input_data_config(s3_bucket),
            output_data_config: {
              s3_output_path: "s3://#{s3_bucket.bucket}/output"
            },
            resource_config: {
              instance_type: select_optimal_instance(input),
              instance_count: 1,
              volume_size_in_gb: 250
            },
            stopping_condition: {
              max_runtime_in_seconds: (input.estimated_training_hours * 3600).to_i
            },
            enable_managed_spot_training: input.use_spot_instances,
            checkpoint_config: {
              s3_uri: "s3://#{s3_bucket.bucket}/checkpoints"
            },
            tags: input.tags.merge(
              "Component" => "sustainable-ml-training",
              "CarbonOptimized" => "true"
            )
          })
        end

        def create_experiment_tracking(input)
          aws_sagemaker_experiment(:"#{input.name}-experiment", {
            experiment_name: "#{input.name}-sustainable-ml",
            description: "Carbon-optimized ML training experiment",
            tags: input.tags
          })
        end

        private

        def build_algorithm_specification(input, fsx_filesystem)
          {
            training_image: get_training_image(input),
            training_input_mode: fsx_filesystem ? "FastFile" : "File",
            enable_sage_maker_metrics_time_series: true
          }
        end

        def build_input_data_config(s3_bucket)
          [{
            channel_name: "training",
            data_source: {
              s3_data_source: {
                s3_data_type: "S3Prefix",
                s3_uri: "s3://#{s3_bucket.bucket}/data/train",
                s3_data_distribution_type: "FullyReplicated"
              }
            }
          }]
        end
      end
    end
  end
end
