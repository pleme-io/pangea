# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS S3 Bucket Lifecycle Configuration
        class S3BucketLifecycleConfigurationAttributes < Dry::Struct
          # S3 bucket to apply lifecycle configuration to
          attribute :bucket, Resources::Types::String

          # Expected bucket owner (optional)
          attribute :expected_bucket_owner, Resources::Types::String.optional

          # Lifecycle rules
          attribute :rule, Resources::Types::Array.of(LifecycleRule).constrained(min_size: 1, max_size: 1000)

          def self.new(attributes = {})
            attrs = super(attributes)

            # Validate unique rule IDs
            rule_ids = attrs.rule.map(&:id)
            if rule_ids.uniq.length != rule_ids.length
              raise Dry::Struct::Error, "Rule IDs must be unique within lifecycle configuration"
            end

            attrs
          end

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
