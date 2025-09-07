# frozen_string_literal: true

require 'pangea/resources/base'
require_relative 'types'

module Pangea
  module Resources
    module AWS
      # AWS Batch Job Queue implementation
      # Provides type-safe function for creating job queues
      def aws_batch_job_queue(name, attributes = {})
        # Validate attributes using dry-struct
        validated_attrs = Types::Types::BatchJobQueueAttributes.new(attributes)
        
        # Create reference that will be returned
        ref = ResourceReference.new(
          type: 'aws_batch_job_queue',
          name: name,
          resource_attributes: validated_attrs.to_h,
          outputs: {
            id: "${aws_batch_job_queue.#{name}.id}",
            arn: "${aws_batch_job_queue.#{name}.arn}",
            name: "${aws_batch_job_queue.#{name}.name}",
            state: "${aws_batch_job_queue.#{name}.state}",
            priority: "${aws_batch_job_queue.#{name}.priority}",
            tags_all: "${aws_batch_job_queue.#{name}.tags_all}"
          }
        )
        
        # Synthesize the Terraform resource
        resource :aws_batch_job_queue, name do
          name validated_attrs.name
          state validated_attrs.state
          priority validated_attrs.priority
          
          # Compute environment order
          validated_attrs.compute_environment_order.each do |compute_env|
            compute_environment_order do
              order compute_env[:order]
              compute_environment compute_env[:compute_environment]
            end
          end
          
          # Tags
          if validated_attrs.tags
            tags validated_attrs.tags
          end
        end
        
        # Return the reference
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)