# frozen_string_literal: true

require_relative 'mediaconvert/job_template'
require_relative 'mediaconvert/preset'
require_relative 'mediaconvert/queue'
require_relative 'mediaconvert/job'

module Pangea
  module Resources
    module AWS
      # AWS Elemental MediaConvert service module
      # Provides type-safe resource functions for video transcoding and processing
      module MediaConvert
        # Creates a MediaConvert job template for reusable transcoding configurations
        #
        # @param name [Symbol] Unique name for the job template resource
        # @param attributes [Hash] Configuration attributes for the job template
        # @return [MediaConvert::JobTemplate::JobTemplateReference] Reference to the created job template
        def aws_mediaconvert_job_template(name, attributes = {})
          resource = MediaConvert::JobTemplate.new(
            name: name,
            synthesizer: synthesizer,
            attributes: MediaConvert::JobTemplate::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a MediaConvert preset for output encoding settings
        #
        # @param name [Symbol] Unique name for the preset resource
        # @param attributes [Hash] Configuration attributes for the preset
        # @return [MediaConvert::Preset::PresetReference] Reference to the created preset
        def aws_mediaconvert_preset(name, attributes = {})
          resource = MediaConvert::Preset.new(
            name: name,
            synthesizer: synthesizer,
            attributes: MediaConvert::Preset::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a MediaConvert queue for job processing prioritization
        #
        # @param name [Symbol] Unique name for the queue resource
        # @param attributes [Hash] Configuration attributes for the queue
        # @return [MediaConvert::Queue::QueueReference] Reference to the created queue
        def aws_mediaconvert_queue(name, attributes = {})
          resource = MediaConvert::Queue.new(
            name: name,
            synthesizer: synthesizer,
            attributes: MediaConvert::Queue::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a MediaConvert job for video transcoding tasks
        #
        # @param name [Symbol] Unique name for the job resource
        # @param attributes [Hash] Configuration attributes for the job
        # @return [MediaConvert::Job::JobReference] Reference to the created job
        def aws_mediaconvert_job(name, attributes = {})
          resource = MediaConvert::Job.new(
            name: name,
            synthesizer: synthesizer,
            attributes: MediaConvert::Job::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end
      end
    end
  end
end