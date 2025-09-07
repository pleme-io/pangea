# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsLaunchConfiguration resources
      # Manages aws launch configuration resources.
      class AwsLaunchConfigurationAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_launch_configuration
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_launch_configuration
      end
    end
      end
    end
  end
end