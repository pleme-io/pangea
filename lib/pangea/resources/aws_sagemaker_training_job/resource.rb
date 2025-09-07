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
require 'pangea/resources/aws_sagemaker_training_job/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # SageMaker Training Job resource for ML model training
      class SageMakerTrainingJob < Base
        def self.resource_type
          'aws_sagemaker_training_job'
        end
        
        def self.attribute_struct
          Types::SageMakerTrainingJobAttributes
        end
      end
      
      def aws_sagemaker_training_job(name, attributes)
        resource = SageMakerTrainingJob.new(
          name: name,
          attributes: attributes
        )
        
        add_resource(resource)
        
        ResourceReference.new(
          name: name,
          type: :aws_sagemaker_training_job,
          attributes: {
            id: "${aws_sagemaker_training_job.#{name}.id}",
            arn: "${aws_sagemaker_training_job.#{name}.arn}",
            training_job_name: "${aws_sagemaker_training_job.#{name}.training_job_name}",
            training_job_status: "${aws_sagemaker_training_job.#{name}.training_job_status}",
            model_artifacts: "${aws_sagemaker_training_job.#{name}.model_artifacts}",
            training_start_time: "${aws_sagemaker_training_job.#{name}.training_start_time}",
            training_end_time: "${aws_sagemaker_training_job.#{name}.training_end_time}",
            
            # Computed attributes
            is_distributed: attributes.dig(:resource_config, :instance_count).to_i > 1,
            is_gpu_training: attributes.dig(:resource_config, :instance_type)&.match?(/ml\.(p|g)/) || false,
            uses_spot_training: attributes[:enable_managed_spot_training] == true,
            has_checkpoints: !attributes[:checkpoint_config].nil?,
            max_runtime_hours: (attributes.dig(:stopping_condition, :max_runtime_in_seconds) || 86400) / 3600.0
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)