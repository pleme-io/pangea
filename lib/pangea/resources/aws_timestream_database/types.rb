# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsTimestreamDatabase resources
      # Provides a Timestream database resource for time series data.
      class TimestreamDatabaseAttributes < Dry::Struct
        attribute :database_name, Resources::Types::String
        attribute :kms_key_id, Resources::Types::String.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_timestream_database

      end
    end
      end
    end
  end
end