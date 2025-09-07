# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Event selector for CloudTrail data events
      class EventSelector < Dry::Struct
        # Read/write type for the event selector (ReadOnly, WriteOnly, All)
        attribute :read_write_type, Resources::Types::String.optional.constrained(included_in: ["ReadOnly", "WriteOnly", "All"])
        
        # Include management events (default true)
        attribute :include_management_events, Resources::Types::Bool.default(true)
        
        # Data resources to log
        attribute :data_resource, Resources::Types::Array.of(
          Types::Hash.schema(
            type: Types::String,        # AWS resource type (e.g., "AWS::S3::Object")
            values: Types::Array.of(Types::String)  # Resource ARNs
          )
        ).default([].freeze)
        
        # Check if this selector includes S3 data events
        def includes_s3_data_events?
          data_resource.any? { |resource| resource[:type] == "AWS::S3::Object" }
        end
        
        # Check if this selector includes Lambda data events
        def includes_lambda_data_events?
          data_resource.any? { |resource| resource[:type] == "AWS::Lambda::Function" }
        end
        
        # Get all resource types being tracked
        def tracked_resource_types
          data_resource.map { |resource| resource[:type] }.uniq
        end
      end

      # Insight selector for CloudTrail Insights
      class InsightSelector < Dry::Struct
        # Insight type (ApiCallRateInsight, ApiErrorRateInsight)
        attribute :insight_type, Resources::Types::String.constrained(included_in: ["ApiCallRateInsight", "ApiErrorRateInsight"])
        
        # Check if this is an API call rate insight
        def is_api_call_rate_insight?
          insight_type == "ApiCallRateInsight"
        end
        
        # Check if this is an API error rate insight  
        def is_api_error_rate_insight?
          insight_type == "ApiErrorRateInsight"
        end
      end

      # Type-safe attributes for AWS CloudTrail resources
      class CloudTrailAttributes < Dry::Struct
        # Trail name (required, 1-128 characters)
        attribute :name, Resources::Types::String
        
        # S3 bucket name for log files (required)
        attributes3_bucket_name :, Resources::Types::String
        
        # S3 key prefix for log files (optional)
        attributes3_key_prefix :, Resources::Types::String.optional
        
        # Include global service events (default true)
        attribute :include_global_service_events, Resources::Types::Bool.default(true)
        
        # Multi-region trail (default true)
        attribute :is_multi_region_trail, Resources::Types::Bool.default(true)
        
        # Enable logging (default true)
        attribute :enable_logging, Resources::Types::Bool.default(true)
        
        # Enable log file validation (default true)
        attribute :enable_log_file_validation, Resources::Types::Bool.default(true)
        
        # KMS key ID for encryption (optional)
        attribute :kms_key_id, Resources::Types::String.optional
        
        # CloudWatch Logs group ARN (optional)
        attribute :cloud_watch_logs_group_arn, Resources::Types::String.optional
        
        # CloudWatch Logs role ARN (optional)  
        attribute :cloud_watch_logs_role_arn, Resources::Types::String.optional
        
        # SNS topic name for notifications (optional)
        attribute :sns_topic_name, Resources::Types::String.optional
        
        # Event selectors for data events
        attribute :event_selector, Resources::Types::Array.of(EventSelector).default([].freeze)
        
        # Insight selectors for CloudTrail Insights
        attribute :insight_selector, Resources::Types::Array.of(InsightSelector).default([].freeze)
        
        # Tags to apply to the trail
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate trail name
          if attrs.name.length < 1 || attrs.name.length > 128
            raise Dry::Struct::Error, "CloudTrail name must be 1-128 characters"
          end
          
          unless attrs.name.match?(/\A[a-zA-Z0-9._\-]+\z/)
            raise Dry::Struct::Error, "CloudTrail name contains invalid characters (must be alphanumeric, dots, hyphens, underscores)"
          end
          
          # Validate CloudWatch Logs integration
          if (attrs.cloud_watch_logs_group_arn.nil?) != (attrs.cloud_watch_logs_role_arn.nil?)
            raise Dry::Struct::Error, "Both cloud_watch_logs_group_arn and cloud_watch_logs_role_arn must be provided together"
          end
          
          # Validate S3 bucket name format
          unless attrs.s3_bucket_name.match?(/\A[a-z0-9.\-]+\z/)
            raise Dry::Struct::Error, "S3 bucket name contains invalid characters"
          end
          
          attrs
        end

        # Check if trail has encryption enabled
        def has_encryption?
          !kms_key_id.nil?
        end

        # Check if CloudWatch Logs integration is configured
        def has_cloudwatch_integration?
          !cloud_watch_logs_group_arn.nil? && !cloud_watch_logs_role_arn.nil?
        end

        # Check if SNS notifications are configured
        def has_sns_notifications?
          !sns_topic_name.nil?
        end

        # Check if trail has event selectors (data events)
        def has_event_selectors?
          event_selector.any?
        end

        # Check if trail has insight selectors  
        def has_insight_selectors?
          insight_selector.any?
        end

        # Check if trail logs S3 data events
        def logs_s3_data_events?
          event_selector.any?(&:includes_s3_data_events?)
        end

        # Check if trail logs Lambda data events
        def logs_lambda_data_events?
          event_selector.any?(&:includes_lambda_data_events?)
        end

        # Get all tracked resource types across all selectors
        def tracked_resource_types
          event_selector.flat_map(&:tracked_resource_types).uniq
        end

        # Check if this is a compliance-focused trail
        def is_compliance_trail?
          enable_log_file_validation && has_encryption? && is_multi_region_trail
        end

        # Check if this is a security monitoring trail
        def is_security_monitoring_trail?
          include_global_service_events && has_cloudwatch_integration? && has_insight_selectors?
        end

        # Get insight types being tracked
        def tracked_insight_types
          insight_selector.map(&:insight_type).uniq
        end

        # Estimate monthly cost in USD (rough estimates based on AWS pricing)
        def estimated_monthly_cost_usd
          base_cost = 0.0
          
          # First trail in each region is free for management events
          # Additional trails cost $2.00/month per region
          if !is_multi_region_trail
            base_cost += 2.00  # Single region additional trail
          end
          
          # Data event costs: $0.10 per 100,000 events
          if has_event_selectors?
            # Estimate based on number of selectors and resource types
            estimated_events_per_month = event_selector.count * 100000  # Conservative estimate
            base_cost += (estimated_events_per_month / 100000.0) * 0.10
          end
          
          # CloudWatch Logs ingestion: ~$0.50/GB
          if has_cloudwatch_integration?
            base_cost += 5.0  # Estimated 10GB/month
          end
          
          # KMS encryption: $0.03 per 10,000 requests
          if has_encryption?
            base_cost += 1.0  # Estimated KMS usage
          end
          
          # Insights cost: $0.35 per 100,000 analyzed events
          if has_insight_selectors?
            base_cost += 3.50  # Estimated 1M events/month
          end
          
          base_cost.round(2)
        end

        # Get recommended retention period based on trail purpose
        def recommended_log_retention_days
          if is_compliance_trail?
            2555  # ~7 years for compliance
          elsif is_security_monitoring_trail?
            365   # 1 year for security
          else
            90    # 3 months default
          end
        end

        # Generate trail summary
        def trail_summary
          features = []
          features << "Multi-region" if is_multi_region_trail
          features << "Encrypted" if has_encryption?
          features << "CloudWatch" if has_cloudwatch_integration?
          features << "Data events" if has_event_selectors?
          features << "Insights" if has_insight_selectors?
          features << "Compliance" if is_compliance_trail?
          
          "#{self.name}: #{features.join(', ')}"
        end
      end

      # Common CloudTrail configurations
      module CloudTrailConfigs
        # Basic compliance trail
        def self.compliance_trail(trail_name:, s3_bucket:, kms_key: nil)
          {
            name: trail_name,
            s3_bucket_name: s3_bucket,
            s3_key_prefix: "compliance-logs",
            include_global_service_events: true,
            is_multi_region_trail: true,
            enable_log_file_validation: true,
            kms_key_id: kms_key,
            tags: {
              Purpose: "compliance",
              Type: "audit-trail",
              Compliance: "required"
            }
          }
        end

        # Security monitoring trail with insights
        def self.security_monitoring_trail(trail_name:, s3_bucket:, cloudwatch_log_group:, cloudwatch_role:)
          {
            name: trail_name,
            s3_bucket_name: s3_bucket,
            s3_key_prefix: "security-logs",
            include_global_service_events: true,
            is_multi_region_trail: true,
            enable_log_file_validation: true,
            cloud_watch_logs_group_arn: cloudwatch_log_group,
            cloud_watch_logs_role_arn: cloudwatch_role,
            insight_selector: [
              { insight_type: "ApiCallRateInsight" },
              { insight_type: "ApiErrorRateInsight" }
            ],
            tags: {
              Purpose: "security-monitoring",
              Type: "security-trail",
              Monitoring: "enabled"
            }
          }
        end

        # Data events trail for S3 and Lambda
        def self.data_events_trail(trail_name:, s3_bucket:, s3_arns: [], lambda_arns: [])
          selectors = []
          
          if s3_arns.any?
            selectors << {
              read_write_type: "All",
              include_management_events: false,
              data_resource: [
                {
                  type: "AWS::S3::Object",
                  values: s3_arns
                }
              ]
            }
          end
          
          if lambda_arns.any?
            selectors << {
              read_write_type: "All", 
              include_management_events: false,
              data_resource: [
                {
                  type: "AWS::Lambda::Function",
                  values: lambda_arns
                }
              ]
            }
          end
          
          {
            name: trail_name,
            s3_bucket_name: s3_bucket,
            s3_key_prefix: "data-events",
            include_global_service_events: false,
            is_multi_region_trail: true,
            event_selector: selectors,
            tags: {
              Purpose: "data-events",
              Type: "data-trail"
            }
          }
        end

        # Development trail (minimal configuration)
        def self.development_trail(trail_name:, s3_bucket:)
          {
            name: trail_name,
            s3_bucket_name: s3_bucket,
            s3_key_prefix: "dev-logs",
            include_global_service_events: false,
            is_multi_region_trail: false,
            enable_log_file_validation: false,
            tags: {
              Purpose: "development",
              Environment: "dev",
              CostOptimized: "true"
            }
          }
        end
      end
    end
      end
    end
  end
end