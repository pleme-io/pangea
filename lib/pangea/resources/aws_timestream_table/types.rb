# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsTimestreamTable resources
      # Provides a Timestream table resource for storing time series data.
      class TimestreamTableAttributes < Dry::Struct
        attribute :database_name, Resources::Types::String
        attribute :table_name, Resources::Types::String
        attribute :retention_properties, Resources::Types::Hash.default({}).optional
        attribute :magnetic_store_write_properties, Resources::Types::Hash.default({}).optional
        attribute :schema, Resources::Types::Hash.default({}).optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_timestream_table

      end
    end
      end
    end
  end
end