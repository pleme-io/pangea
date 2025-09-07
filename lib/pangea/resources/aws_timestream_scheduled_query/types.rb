# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsTimestreamScheduledQuery resources
      # Provides a Timestream scheduled query resource.
      class TimestreamScheduledQueryAttributes < Dry::Struct
        attribute :name, Resources::Types::String
        attribute :query_string, Resources::Types::String
        attribute :schedule_configuration, Resources::Types::Hash.default({})
        attribute :notification_configuration, Resources::Types::Hash.default({})
        attribute :target_configuration, Resources::Types::Hash.default({}).optional
        attribute :client_token, Resources::Types::String.optional
        attribute :scheduled_query_execution_role_arn, Resources::Types::String
        attribute :error_report_configuration, Resources::Types::Hash.default({}).optional
        attribute :kms_key_id, Resources::Types::String.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_timestream_scheduled_query

      end
    end
      end
    end
  end
end