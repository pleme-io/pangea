# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsElbServiceAccount resources
      # Manages aws elb service account resources.
      class AwsElbServiceAccountAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_elb_service_account
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_elb_service_account
      end
    end
      end
    end
  end
end