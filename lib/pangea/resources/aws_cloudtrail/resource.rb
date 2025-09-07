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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_cloudtrail/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudTrail with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudTrail attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cloudtrail(name, attributes = {})
        # Validate attributes using dry-struct
        trail_attrs = Types::CloudTrailAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudtrail, name) do
          # Required attributes
          self.name trail_attrs.name
          s3_bucket_name trail_attrs.s3_bucket_name
          
          # Optional basic attributes
          s3_key_prefix trail_attrs.s3_key_prefix if trail_attrs.s3_key_prefix
          include_global_service_events trail_attrs.include_global_service_events
          is_multi_region_trail trail_attrs.is_multi_region_trail
          enable_logging trail_attrs.enable_logging
          enable_log_file_validation trail_attrs.enable_log_file_validation
          
          # Encryption
          kms_key_id trail_attrs.kms_key_id if trail_attrs.kms_key_id
          
          # CloudWatch Logs integration
          cloud_watch_logs_group_arn trail_attrs.cloud_watch_logs_group_arn if trail_attrs.cloud_watch_logs_group_arn
          cloud_watch_logs_role_arn trail_attrs.cloud_watch_logs_role_arn if trail_attrs.cloud_watch_logs_role_arn
          
          # SNS notifications
          sns_topic_name trail_attrs.sns_topic_name if trail_attrs.sns_topic_name
          
          # Event selectors for data events
          trail_attrs.event_selector.each do |selector|
            event_selector do
              read_write_type selector.read_write_type if selector.read_write_type
              include_management_events selector.include_management_events
              
              selector.data_resource.each do |resource|
                data_resource do
                  type resource[:type]
                  values resource[:values]
                end
              end
            end
          end
          
          # Insight selectors
          trail_attrs.insight_selector.each do |insight|
            insight_selector do
              insight_type insight.insight_type
            end
          end
          
          # Apply tags if present
          if trail_attrs.tags.any?
            tags do
              trail_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cloudtrail',
          name: name,
          resource_attributes: trail_attrs.to_h,
          outputs: {
            id: "${aws_cloudtrail.#{name}.id}",
            arn: "${aws_cloudtrail.#{name}.arn}",
            name: "${aws_cloudtrail.#{name}.name}",
            home_region: "${aws_cloudtrail.#{name}.home_region}",
            s3_bucket_name: "${aws_cloudtrail.#{name}.s3_bucket_name}",
            s3_key_prefix: "${aws_cloudtrail.#{name}.s3_key_prefix}",
            include_global_service_events: "${aws_cloudtrail.#{name}.include_global_service_events}",
            is_multi_region_trail: "${aws_cloudtrail.#{name}.is_multi_region_trail}",
            enable_logging: "${aws_cloudtrail.#{name}.enable_logging}",
            kms_key_id: "${aws_cloudtrail.#{name}.kms_key_id}",
            cloud_watch_logs_group_arn: "${aws_cloudtrail.#{name}.cloud_watch_logs_group_arn}",
            cloud_watch_logs_role_arn: "${aws_cloudtrail.#{name}.cloud_watch_logs_role_arn}",
            sns_topic_arn: "${aws_cloudtrail.#{name}.sns_topic_arn}",
            tags_all: "${aws_cloudtrail.#{name}.tags_all}"
          },
          computed_properties: {
            has_encryption: trail_attrs.has_encryption?,
            has_cloudwatch_integration: trail_attrs.has_cloudwatch_integration?,
            has_sns_notifications: trail_attrs.has_sns_notifications?,
            has_event_selectors: trail_attrs.has_event_selectors?,
            has_insight_selectors: trail_attrs.has_insight_selectors?,
            logs_s3_data_events: trail_attrs.logs_s3_data_events?,
            logs_lambda_data_events: trail_attrs.logs_lambda_data_events?,
            tracked_resource_types: trail_attrs.tracked_resource_types,
            tracked_insight_types: trail_attrs.tracked_insight_types,
            is_compliance_trail: trail_attrs.is_compliance_trail?,
            is_security_monitoring_trail: trail_attrs.is_security_monitoring_trail?,
            estimated_monthly_cost_usd: trail_attrs.estimated_monthly_cost_usd,
            recommended_log_retention_days: trail_attrs.recommended_log_retention_days,
            trail_summary: trail_attrs.trail_summary
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)