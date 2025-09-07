# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsTimestreamBatchLoadTask resources
      # Provides a Timestream batch load task resource.
      class TimestreamBatchLoadTaskAttributes < Dry::Struct
        attribute :database_name, Resources::Types::String
        attribute :table_name, Resources::Types::String
        attribute :data_source_configuration, Resources::Types::Hash.default({})
        attribute :data_model_configuration, Resources::Types::Hash.default({}).optional
        attribute :report_configuration, Resources::Types::Hash.default({}).optional
        attribute :target_database_name, Resources::Types::String.optional
        attribute :target_table_name, Resources::Types::String.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_timestream_batch_load_task

      end
    end
      end
    end
  end
end