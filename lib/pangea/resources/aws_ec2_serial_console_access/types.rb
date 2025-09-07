# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsEc2SerialConsoleAccess resources
      # Manages aws ec2 serial console access resources.
      class AwsEc2SerialConsoleAccessAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_ec2_serial_console_access
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_ec2_serial_console_access
      end
    end
      end
    end
  end
end