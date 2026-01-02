# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Common CloudTrail configurations
        module CloudTrailConfigs
          def self.compliance_trail(trail_name:, s3_bucket:, kms_key: nil)
            {
              name: trail_name,
              s3_bucket_name: s3_bucket,
              s3_key_prefix: 'compliance-logs',
              include_global_service_events: true,
              is_multi_region_trail: true,
              enable_log_file_validation: true,
              kms_key_id: kms_key,
              tags: { Purpose: 'compliance', Type: 'audit-trail', Compliance: 'required' }
            }
          end

          def self.security_monitoring_trail(trail_name:, s3_bucket:, cloudwatch_log_group:, cloudwatch_role:)
            {
              name: trail_name,
              s3_bucket_name: s3_bucket,
              s3_key_prefix: 'security-logs',
              include_global_service_events: true,
              is_multi_region_trail: true,
              enable_log_file_validation: true,
              cloud_watch_logs_group_arn: cloudwatch_log_group,
              cloud_watch_logs_role_arn: cloudwatch_role,
              insight_selector: [
                { insight_type: 'ApiCallRateInsight' },
                { insight_type: 'ApiErrorRateInsight' }
              ],
              tags: { Purpose: 'security-monitoring', Type: 'security-trail', Monitoring: 'enabled' }
            }
          end

          def self.data_events_trail(trail_name:, s3_bucket:, s3_arns: [], lambda_arns: [])
            selectors = []

            if s3_arns.any?
              selectors << {
                read_write_type: 'All',
                include_management_events: false,
                data_resource: [{ type: 'AWS::S3::Object', values: s3_arns }]
              }
            end

            if lambda_arns.any?
              selectors << {
                read_write_type: 'All',
                include_management_events: false,
                data_resource: [{ type: 'AWS::Lambda::Function', values: lambda_arns }]
              }
            end

            {
              name: trail_name,
              s3_bucket_name: s3_bucket,
              s3_key_prefix: 'data-events',
              include_global_service_events: false,
              is_multi_region_trail: true,
              event_selector: selectors,
              tags: { Purpose: 'data-events', Type: 'data-trail' }
            }
          end

          def self.development_trail(trail_name:, s3_bucket:)
            {
              name: trail_name,
              s3_bucket_name: s3_bucket,
              s3_key_prefix: 'dev-logs',
              include_global_service_events: false,
              is_multi_region_trail: false,
              enable_log_file_validation: false,
              tags: { Purpose: 'development', Environment: 'dev', CostOptimized: 'true' }
            }
          end
        end
      end
    end
  end
end
