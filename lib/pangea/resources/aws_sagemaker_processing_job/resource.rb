# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/aws_sagemaker_processing_job/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # SageMaker Processing Job resource for data preprocessing and feature engineering
      class SageMakerProcessingJob < Base
        def self.resource_type
          'aws_sagemaker_processing_job'
        end
        
        def self.attribute_struct
          Types::SageMakerProcessingJobAttributes
        end
      end
      
      def aws_sagemaker_processing_job(name, attributes)
        resource = SageMakerProcessingJob.new(
          name: name,
          attributes: attributes
        )
        
        add_resource(resource)
        
        ResourceReference.new(
          name: name,
          type: :aws_sagemaker_processing_job,
          attributes: {
            id: "${aws_sagemaker_processing_job.#{name}.id}",
            arn: "${aws_sagemaker_processing_job.#{name}.arn}",
            processing_job_name: "${aws_sagemaker_processing_job.#{name}.processing_job_name}",
            processing_job_status: "${aws_sagemaker_processing_job.#{name}.processing_job_status}",
            is_distributed: attributes.dig(:processing_resources, :cluster_config, :instance_count).to_i > 1,
            uses_feature_store: attributes.dig(:processing_output_config, :outputs)&.any? { |o| o[:feature_store_output] } || false
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)