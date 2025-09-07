# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    # AWS IoT Thing Principal Attachment Types
    # 
    # Thing principal attachments bind X.509 certificates or other principals to IoT things.
    # This enables secure authentication and authorization for device communication with AWS IoT Core.
    # Each thing can have multiple principals, and each principal can be attached to multiple things.
    module AwsIotThingPrincipalAttachmentTypes
      # Main attributes for IoT thing principal attachment resource
      class Attributes < Dry::Struct
        schema schema.strict

        # ARN of the principal (certificate) to attach to the thing
        attribute :principal, Resources::Types::String

        # Name of the thing to attach the principal to
        attribute :thing_name, Resources::Types::String
      end

      # Output attributes from thing principal attachment resource
      class Outputs < Dry::Struct
        schema schema.strict

        # The attachment ID (combination of thing name and principal)
        attribute :id, Resources::Types::String

        # The ARN of the attached principal
        attribute :principal, Resources::Types::String

        # The name of the thing
        attribute :thing_name, Resources::Types::String
      end
    end
  end
end