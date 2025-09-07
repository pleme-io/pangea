# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsEc2AvailabilityZoneGroup resources
      # Manages aws ec2 availability zone group resources.
      class AwsEc2AvailabilityZoneGroupAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_ec2_availability_zone_group
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_ec2_availability_zone_group
      end
    end
      end
    end
  end
end