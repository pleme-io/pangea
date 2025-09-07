# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    # AWS IoT Wireless Destination Types
    # 
    # Wireless destinations define where device messages are sent for processing.
    # They support various AWS services like IoT Core, IoT Analytics, and custom endpoints.
    module AwsIotWirelessDestinationTypes
      # Main attributes for IoT wireless destination resource
      class Attributes < Dry::Struct
        schema schema.strict

        # Name of the wireless destination
        attribute :name, Resources::Types::String

        # Expression type for routing rules
        attribute :expression_type, Resources::Types::String.enum('RuleName', 'MqttTopic')

        # Expression for message routing
        attribute :expression, Resources::Types::String

        # Description of the destination
        attribute :description, Resources::Types::String.optional

        # IAM role ARN for destination access
        attribute :role_arn, Resources::Types::String.optional

        # Resource tags
        attribute :tags, Resources::Types::Hash.map(Types::String, Types::String).optional
      end

      # Output attributes from wireless destination resource
      class Outputs < Dry::Struct
        schema schema.strict

        # The destination ARN
        attribute :arn, Resources::Types::String

        # The destination name
        attribute :name, Resources::Types::String

        # The destination ID
        attribute :id, Resources::Types::String
      end
    end
  end
end