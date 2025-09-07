# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsEc2DedicatedHost resources
      # Manages aws ec2 dedicated host resources.
      class AwsEc2DedicatedHostAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_ec2_dedicated_host
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_ec2_dedicated_host
      end
    end
      end
    end
  end
end