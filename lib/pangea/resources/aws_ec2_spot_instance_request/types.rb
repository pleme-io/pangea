# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsEc2SpotInstanceRequest resources
      # Manages aws ec2 spot instance request resources.
      class AwsEc2SpotInstanceRequestAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_ec2_spot_instance_request
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_ec2_spot_instance_request
      end
    end
      end
    end
  end
end