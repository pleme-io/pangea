# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsAutoscalingTrafficSourceAttachment resources
      # Manages aws autoscaling traffic source attachment resources.
      class AwsAutoscalingTrafficSourceAttachmentAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_autoscaling_traffic_source_attachment
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_autoscaling_traffic_source_attachment
      end
    end
      end
    end
  end
end