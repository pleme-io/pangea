# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # S3 lifecycle rule abort incomplete multipart upload
        class LifecycleAbortIncompleteMultipartUpload < Dry::Struct
          attribute :days_after_initiation, Resources::Types::Integer.constrained(gt: 0)
        end

        # S3 lifecycle rule
        class LifecycleRule < Dry::Struct
          attribute :id, Resources::Types::String
          attribute :status, Resources::Types::String.enum("Enabled", "Disabled")
          attribute? :abort_incomplete_multipart_upload, LifecycleAbortIncompleteMultipartUpload.optional
          attribute? :expiration, LifecycleExpiration.optional
          attribute? :filter, LifecycleFilter.optional
          attribute? :noncurrent_version_expiration, LifecycleNoncurrentVersionExpiration.optional
          attribute :noncurrent_version_transition, Resources::Types::Array.of(LifecycleNoncurrentVersionTransition).optional
          attribute :prefix, Resources::Types::String.optional
          attribute :transition, Resources::Types::Array.of(LifecycleTransition).optional

          def enabled?
            status == "Enabled"
          end

          def disabled?
            status == "Disabled"
          end

          def has_expiration?
            !expiration.nil?
          end

          def has_transitions?
            !transition.nil? && transition.any?
          end

          def has_filter?
            !filter.nil?
          end
        end
      end
    end
  end
end
