# frozen_string_literal: true

require_relative 'batch/compute_environment'
require_relative 'batch/job_queue'
require_relative 'batch/job_definition'
require_relative 'batch/job'
require_relative 'batch/scheduling_policy'

module Pangea
  module Resources
    module AWS
      # AWS Batch service module
      # Provides type-safe resource functions for scalable batch computing workloads
      module Batch
        # Creates a Batch compute environment for job processing infrastructure
        #
        # @param name [Symbol] Unique name for the compute environment resource
        # @param attributes [Hash] Configuration attributes for the compute environment
        # @return [Batch::ComputeEnvironment::ComputeEnvironmentReference] Reference to the created compute environment
        def aws_batch_compute_environment(name, attributes = {})
          resource = Batch::ComputeEnvironment.new(
            name: name,
            synthesizer: synthesizer,
            attributes: Batch::ComputeEnvironment::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a Batch job queue for routing jobs to compute environments
        #
        # @param name [Symbol] Unique name for the job queue resource
        # @param attributes [Hash] Configuration attributes for the job queue
        # @return [Batch::JobQueue::JobQueueReference] Reference to the created job queue
        def aws_batch_job_queue(name, attributes = {})
          resource = Batch::JobQueue.new(
            name: name,
            synthesizer: synthesizer,
            attributes: Batch::JobQueue::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a Batch job definition template for containerized workloads
        #
        # @param name [Symbol] Unique name for the job definition resource
        # @param attributes [Hash] Configuration attributes for the job definition
        # @return [Batch::JobDefinition::JobDefinitionReference] Reference to the created job definition
        def aws_batch_job_definition(name, attributes = {})
          resource = Batch::JobDefinition.new(
            name: name,
            synthesizer: synthesizer,
            attributes: Batch::JobDefinition::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Submits a Batch job for processing
        #
        # @param name [Symbol] Unique name for the job resource
        # @param attributes [Hash] Configuration attributes for the job
        # @return [Batch::Job::JobReference] Reference to the created job
        def aws_batch_job(name, attributes = {})
          resource = Batch::Job.new(
            name: name,
            synthesizer: synthesizer,
            attributes: Batch::Job::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a Batch scheduling policy for job resource allocation
        #
        # @param name [Symbol] Unique name for the scheduling policy resource
        # @param attributes [Hash] Configuration attributes for the scheduling policy
        # @return [Batch::SchedulingPolicy::SchedulingPolicyReference] Reference to the created scheduling policy
        def aws_batch_scheduling_policy(name, attributes = {})
          resource = Batch::SchedulingPolicy.new(
            name: name,
            synthesizer: synthesizer,
            attributes: Batch::SchedulingPolicy::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end
      end
    end
  end
end