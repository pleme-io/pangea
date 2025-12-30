# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/types'
require_relative 'selectors'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS CloudTrail resources
        class CloudTrailAttributes < Dry::Struct
          attribute :name, Resources::Types::String
          attribute :s3_bucket_name, Resources::Types::String
          attribute :s3_key_prefix, Resources::Types::String.optional
          attribute :include_global_service_events, Resources::Types::Bool.default(true)
          attribute :is_multi_region_trail, Resources::Types::Bool.default(true)
          attribute :enable_logging, Resources::Types::Bool.default(true)
          attribute :enable_log_file_validation, Resources::Types::Bool.default(true)
          attribute :kms_key_id, Resources::Types::String.optional
          attribute :cloud_watch_logs_group_arn, Resources::Types::String.optional
          attribute :cloud_watch_logs_role_arn, Resources::Types::String.optional
          attribute :sns_topic_name, Resources::Types::String.optional
          attribute :event_selector, Resources::Types::Array.of(EventSelector).default([].freeze)
          attribute :insight_selector, Resources::Types::Array.of(InsightSelector).default([].freeze)
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          def self.new(attributes = {})
            attrs = super(attributes)
            validate_name!(attrs)
            validate_cloudwatch!(attrs)
            validate_s3_bucket!(attrs)
            attrs
          end

          def self.validate_name!(attrs)
            raise Dry::Struct::Error, 'CloudTrail name must be 1-128 characters' if attrs.name.length < 1 || attrs.name.length > 128
            raise Dry::Struct::Error, 'CloudTrail name contains invalid characters (must be alphanumeric, dots, hyphens, underscores)' unless attrs.name.match?(/\A[a-zA-Z0-9._\-]+\z/)
          end

          def self.validate_cloudwatch!(attrs)
            raise Dry::Struct::Error, 'Both cloud_watch_logs_group_arn and cloud_watch_logs_role_arn must be provided together' if attrs.cloud_watch_logs_group_arn.nil? != attrs.cloud_watch_logs_role_arn.nil?
          end

          def self.validate_s3_bucket!(attrs)
            raise Dry::Struct::Error, 'S3 bucket name contains invalid characters' unless attrs.s3_bucket_name.match?(/\A[a-z0-9.\-]+\z/)
          end

          def has_encryption? = !kms_key_id.nil?
          def has_cloudwatch_integration? = !cloud_watch_logs_group_arn.nil? && !cloud_watch_logs_role_arn.nil?
          def has_sns_notifications? = !sns_topic_name.nil?
          def has_event_selectors? = event_selector.any?
          def has_insight_selectors? = insight_selector.any?
          def logs_s3_data_events? = event_selector.any?(&:includes_s3_data_events?)
          def logs_lambda_data_events? = event_selector.any?(&:includes_lambda_data_events?)
          def tracked_resource_types = event_selector.flat_map(&:tracked_resource_types).uniq
          def is_compliance_trail? = enable_log_file_validation && has_encryption? && is_multi_region_trail
          def is_security_monitoring_trail? = include_global_service_events && has_cloudwatch_integration? && has_insight_selectors?
          def tracked_insight_types = insight_selector.map(&:insight_type).uniq

          def estimated_monthly_cost_usd
            base_cost = is_multi_region_trail ? 0.0 : 2.00
            base_cost += (event_selector.count * 100_000 / 100_000.0) * 0.10 if has_event_selectors?
            base_cost += 5.0 if has_cloudwatch_integration?
            base_cost += 1.0 if has_encryption?
            base_cost += 3.50 if has_insight_selectors?
            base_cost.round(2)
          end

          def recommended_log_retention_days
            return 2555 if is_compliance_trail?
            return 365 if is_security_monitoring_trail?

            90
          end

          def trail_summary
            features = []
            features << 'Multi-region' if is_multi_region_trail
            features << 'Encrypted' if has_encryption?
            features << 'CloudWatch' if has_cloudwatch_integration?
            features << 'Data events' if has_event_selectors?
            features << 'Insights' if has_insight_selectors?
            features << 'Compliance' if is_compliance_trail?
            "#{name}: #{features.join(', ')}"
          end
        end
      end
    end
  end
end
