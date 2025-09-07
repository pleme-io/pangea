# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsNeptuneEventSubscription resources
      # Provides a Neptune event subscription resource.
      class NeptuneEventSubscriptionAttributes < Dry::Struct
        attribute :name, Resources::Types::String
        attribute :sns_topic_arn, Resources::Types::String
        attribute :source_type, Resources::Types::String.optional
        attribute :source_ids, Resources::Types::Array.of(Types::String).default([].freeze).optional
        attribute :event_categories, Resources::Types::Array.of(Types::String).default([].freeze).optional
        attribute :enabled, Resources::Types::Bool.optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_neptune_event_subscription

      end
    end
      end
    end
  end
end