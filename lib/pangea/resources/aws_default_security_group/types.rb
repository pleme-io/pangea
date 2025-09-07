# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsDefaultSecurityGroup resources
      # Manages aws default security group resources.
      class AwsDefaultSecurityGroupAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_default_security_group
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_default_security_group
      end
    end
      end
    end
  end
end