# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # S3 lifecycle rule expiration
      class LifecycleExpiration < Dry::Struct
        attribute :date, Resources::Types::String.optional
        attribute :days, Resources::Types::Integer.optional
        attribute :expired_object_delete_marker, Resources::Types::Bool.optional

        # Custom validation
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

      # S3 lifecycle rule transition
      class LifecycleTransition < Dry::Struct
        attribute :date, Resources::Types::String.optional
        attribute :days, Resources::Types::Integer.optional
        attribute :storage_class, Resources::Types::String.enum("STANDARD_IA", "ONEZONE_IA", "REDUCED_REDUNDANCY", "GLACIER", "DEEP_ARCHIVE", "INTELLIGENT_TIERING", "GLACIER_IR")

        # Custom validation
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
        attribute :storage_class, Resources::Types::String.enum("STANDARD_IA", "ONEZONE_IA", "REDUCED_REDUNDANCY", "GLACIER", "DEEP_ARCHIVE", "INTELLIGENT_TIERING", "GLACIER_IR")
      end

      # S3 lifecycle rule abort incomplete multipart upload
      class LifecycleAbortIncompleteMultipartUpload < Dry::Struct
        attribute :days_after_initiation, Resources::Types::Integer.constrained(gt: 0)
      end

      # S3 lifecycle rule filter tag
      class LifecycleFilterTag < Dry::Struct
        attribute :key, Resources::Types::String
        attribute :value, Resources::Types::String
      end

      # S3 lifecycle rule filter and block
      class LifecycleFilterAnd < Dry::Struct
        attribute :object_size_greater_than, Resources::Types::Integer.optional
        attribute :object_size_less_than, Resources::Types::Integer.optional
        attribute :prefix, Resources::Types::String.optional
        attribute :tags, Resources::Types::Array.of(LifecycleFilterTag).optional
      end

      # S3 lifecycle rule filter
      class LifecycleFilter < Dry::Struct
        attribute? :and_condition, LifecycleFilterAnd.optional
        attribute :object_size_greater_than, Resources::Types::Integer.optional
        attribute :object_size_less_than, Resources::Types::Integer.optional
        attribute :prefix, Resources::Types::String.optional
        attribute? :tag, LifecycleFilterTag.optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Count non-nil filter conditions
          conditions = [
            attrs.and_condition,
            attrs.object_size_greater_than, 
            attrs.object_size_less_than,
            attrs.prefix,
            attrs.tag
          ].compact.count
          
          # Can only have one top-level filter condition
          if conditions > 1
            raise Dry::Struct::Error, "Can only specify one top-level filter condition"
          end
          
          attrs
        end
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

        # Helper methods
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

      # Type-safe attributes for AWS S3 Bucket Lifecycle Configuration
      class S3BucketLifecycleConfigurationAttributes < Dry::Struct
        # S3 bucket to apply lifecycle configuration to
        attribute :bucket, Resources::Types::String
        
        # Expected bucket owner (optional)
        attribute :expected_bucket_owner, Resources::Types::String.optional
        
        # Lifecycle rules
        attribute :rule, Resources::Types::Array.of(LifecycleRule).constrained(min_size: 1, max_size: 1000)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate unique rule IDs
          rule_ids = attrs.rule.map(&:id)
          if rule_ids.uniq.length != rule_ids.length
            raise Dry::Struct::Error, "Rule IDs must be unique within lifecycle configuration"
          end
          
          attrs
        end

        # Helper methods
        def enabled_rules
          rule.select(&:enabled?)
        end

        def disabled_rules
          rule.select(&:disabled?)
        end

        def rules_with_expiration
          rule.select(&:has_expiration?)
        end

        def rules_with_transitions
          rule.select(&:has_transitions?)
        end

        def total_rules_count
          rule.length
        end
      end
    end
      end
    end
  end
end