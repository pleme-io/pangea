# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsEc2InstanceMetadataDefaults resources
      # Manages aws ec2 instance metadata defaults resources.
      class AwsEc2InstanceMetadataDefaultsAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_ec2_instance_metadata_defaults
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_ec2_instance_metadata_defaults
      end
    end
      end
    end
  end
end