# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsEc2CapacityReservation resources
      # Manages aws ec2 capacity reservation resources.
      class AwsEc2CapacityReservationAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_ec2_capacity_reservation
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_ec2_capacity_reservation
      end
    end
      end
    end
  end
end