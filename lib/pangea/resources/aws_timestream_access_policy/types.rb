# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsTimestreamAccessPolicy resources
      # Provides a Timestream access policy resource.
      class TimestreamAccessPolicyAttributes < Dry::Struct
        attribute :database_name, Resources::Types::String
        attribute :table_name, Resources::Types::String.optional
        attribute :policy_document, Resources::Types::String
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_timestream_access_policy

      end
    end
      end
    end
  end
end