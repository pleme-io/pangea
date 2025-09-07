# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsTimestreamTableRetentionProperties resources
      # Provides a Timestream table retention properties resource.
      class TimestreamTableRetentionPropertiesAttributes < Dry::Struct
        attribute :database_name, Resources::Types::String
        attribute :table_name, Resources::Types::String
        attribute :magnetic_store_retention_period_in_days, Resources::Types::Integer.optional
        attribute :memory_store_retention_period_in_hours, Resources::Types::Integer.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_timestream_table_retention_properties

      end
    end
      end
    end
  end
end