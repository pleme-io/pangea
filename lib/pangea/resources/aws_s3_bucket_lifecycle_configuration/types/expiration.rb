# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # S3 lifecycle rule expiration
        class LifecycleExpiration < Dry::Struct
          attribute :date, Resources::Types::String.optional
          attribute :days, Resources::Types::Integer.optional
          attribute :expired_object_delete_marker, Resources::Types::Bool.optional

          def self.new(attributes = {})
            attrs = super(attributes)

            # Must specify either date or days, but not both
            if attrs.date && attrs.days
              raise Dry::Struct::Error, "Cannot specify both 'date' and 'days' for expiration"
            end

            if !attrs.date && !attrs.days && !attrs.expired_object_delete_marker
              raise Dry::Struct::Error, "Must specify at least one expiration property"
            end

            attrs
          end
        end

        # S3 lifecycle rule noncurrent version expiration
        class LifecycleNoncurrentVersionExpiration < Dry::Struct
          attribute :noncurrent_days, Resources::Types::Integer.optional
          attribute :newer_noncurrent_versions, Resources::Types::Integer.optional
        end
      end
    end
  end
end
