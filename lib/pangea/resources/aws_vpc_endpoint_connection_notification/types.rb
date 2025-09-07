# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsVpcEndpointConnectionNotification resources
      # Manages VPC endpoint connection notifications for monitoring endpoint state changes.
      class VpcEndpointConnectionNotificationAttributes < Dry::Struct
        attribute :vpc_endpoint_service_id, Resources::Types::String
        attribute :connection_notification_arn, Resources::Types::String
        attribute :connection_events, Resources::Types::Array.of(Types::String.enum('Accept', 'Connect', 'Delete', 'Reject'))
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # vpc_endpoint_service_id must be valid VPC endpoint service ID
          # connection_notification_arn must be valid SNS topic ARN
          # connection_events must not be empty
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_vpc_endpoint_connection_notification
      end
    end
      end
    end
  end
end