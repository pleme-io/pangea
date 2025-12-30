# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Storage class enum for lifecycle transitions
        LIFECYCLE_STORAGE_CLASSES = %w[
          STANDARD_IA
          ONEZONE_IA
          REDUCED_REDUNDANCY
          GLACIER
          DEEP_ARCHIVE
          INTELLIGENT_TIERING
          GLACIER_IR
        ].freeze

        # S3 lifecycle rule transition
        class LifecycleTransition < Dry::Struct
          attribute :date, Resources::Types::String.optional
          attribute :days, Resources::Types::Integer.optional
          attribute :storage_class, Resources::Types::String.enum(*LIFECYCLE_STORAGE_CLASSES)

          def self.new(attributes = {})
            attrs = super(attributes)

            # Must specify either date or days, but not both
            if attrs.date && attrs.days
              raise Dry::Struct::Error, "Cannot specify both 'date' and 'days' for transition"
            end

            if !attrs.date && !attrs.days
              raise Dry::Struct::Error, "Must specify either 'date' or 'days' for transition"
            end

            attrs
          end
        end

        # S3 lifecycle rule noncurrent version transition
        class LifecycleNoncurrentVersionTransition < Dry::Struct
          attribute :noncurrent_days, Resources::Types::Integer.optional
          attribute :newer_noncurrent_versions, Resources::Types::Integer.optional
          attribute :storage_class, Resources::Types::String.enum(*LIFECYCLE_STORAGE_CLASSES)
        end
      end
    end
  end
end
