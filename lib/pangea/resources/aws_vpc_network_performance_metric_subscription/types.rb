# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsVpcNetworkPerformanceMetricSubscription resources
      # Manages aws vpc network performance metric subscription resources.
      class AwsVpcNetworkPerformanceMetricSubscriptionAttributes < Dry::Struct
        # TODO: Define specific attributes for aws_vpc_network_performance_metric_subscription
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # TODO: Add custom validation logic
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_vpc_network_performance_metric_subscription
      end
    end
      end
    end
  end
end