# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS S3 Bucket Versioning resources
      class S3BucketVersioningAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Bucket name (required)
        attribute :bucket, Resources::Types::String

        # Versioning configuration (required)
        attribute :versioning_configuration, Resources::Types::Hash.schema(
          status: Resources::Types::String.enum('Enabled', 'Suspended'),
          mfa_delete?: Resources::Types::String.enum('Enabled', 'Disabled').optional
        )

        # Expected bucket owner for multi-account scenarios
        attribute? :expected_bucket_owner, Resources::Types::String.optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Ensure versioning_configuration is provided
          unless attrs.versioning_configuration
            raise Dry::Struct::Error, "versioning_configuration is required"
          end

          attrs
        end

        # Helper methods
        def versioning_enabled?
          versioning_configuration[:status] == 'Enabled'
        end

        def versioning_suspended?
          versioning_configuration[:status] == 'Suspended'
        end

        def mfa_delete_enabled?
          versioning_configuration[:mfa_delete] == 'Enabled'
        end

        def mfa_delete_configured?
          versioning_configuration.key?(:mfa_delete)
        end

        def status
          versioning_configuration[:status]
        end
      end
    end
      end
    end
  end
end