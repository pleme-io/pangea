# frozen_string_literal: true

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