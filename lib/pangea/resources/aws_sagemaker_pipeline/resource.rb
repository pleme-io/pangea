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
require 'pangea/resources/aws_sagemaker_pipeline/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # SageMaker Pipeline resource for ML workflow orchestration
      class SageMakerPipeline < Base
        def self.resource_type
          'aws_sagemaker_pipeline'
        end
        
        def self.attribute_struct
          Types::SageMakerPipelineAttributes
        end
      end
      
      def aws_sagemaker_pipeline(name, attributes)
        resource = SageMakerPipeline.new(
          name: name,
          attributes: attributes
        )
        
        add_resource(resource)
        
        ResourceReference.new(
          name: name,
          type: :aws_sagemaker_pipeline,
          attributes: {
            id: "${aws_sagemaker_pipeline.#{name}.id}",
            arn: "${aws_sagemaker_pipeline.#{name}.arn}",
            pipeline_name: "${aws_sagemaker_pipeline.#{name}.pipeline_name}",
            pipeline_status: "${aws_sagemaker_pipeline.#{name}.pipeline_status}",
            has_parallelism: !attributes[:parallelism_configuration].nil?,
            max_parallel_steps: attributes.dig(:parallelism_configuration, :max_parallel_execution_steps) || 50
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)