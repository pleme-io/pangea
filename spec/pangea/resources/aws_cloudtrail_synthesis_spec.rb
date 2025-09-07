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


require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/aws_cloudtrail/resource'
require 'pangea/resources/aws_cloudtrail/types'

RSpec.describe 'aws_cloudtrail synthesis' do
  include Pangea::Resources::AWS
  
  let(:synthesizer) { TerraformSynthesizer.new }
  
  describe 'terraform synthesis' do
    it 'synthesizes basic CloudTrail' do
      synthesizer.instance_eval do
        aws_cloudtrail(:basic_trail, {
          name: "my-basic-trail",
          s3_bucket_name: "my-cloudtrail-bucket"
        })
      end
      
      result = synthesizer.synthesis
      trail = result[:resource][:aws_cloudtrail][:basic_trail]
      
      expect(trail).to include(
        name: "my-basic-trail",
        s3_bucket_name: "my-cloudtrail-bucket",
        include_global_service_events: true,
        is_multi_region_trail: true,
        enable_logging: true,
        enable_log_file_validation: true
      )
      expect(trail).not_to have_key(:kms_key_id)
      expect(trail).not_to have_key(:cloud_watch_logs_group_arn)
    end
    
    it 'synthesizes encrypted CloudTrail' do
      synthesizer.instance_eval do
        aws_cloudtrail(:encrypted_trail, {
          name: "encrypted-trail",
          s3_bucket_name: "encrypted-bucket",
          kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
        })
      end
      
      result = synthesizer.synthesis
      trail = result[:resource][:aws_cloudtrail][:encrypted_trail]
      
      expect(trail[:name]).to eq("encrypted-trail")
      expect(trail[:s3_bucket_name]).to eq("encrypted-bucket")
      expect(trail[:kms_key_id]).to eq("arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012")
    end
    
    it 'synthesizes CloudTrail with CloudWatch integration' do
      synthesizer.instance_eval do
        aws_cloudtrail(:monitored_trail, {
          name: "monitored-trail",
          s3_bucket_name: "monitored-bucket",
          cloud_watch_logs_group_arn: "arn:aws:logs:us-east-1:123456789012:log-group:/aws/cloudtrail/my-trail",
          cloud_watch_logs_role_arn: "arn:aws:iam::123456789012:role/CloudTrail_CloudWatchLogs_Role"
        })
      end
      
      result = synthesizer.synthesis
      trail = result[:resource][:aws_cloudtrail][:monitored_trail]
      
      expect(trail[:cloud_watch_logs_group_arn]).to eq("arn:aws:logs:us-east-1:123456789012:log-group:/aws/cloudtrail/my-trail")
      expect(trail[:cloud_watch_logs_role_arn]).to eq("arn:aws:iam::123456789012:role/CloudTrail_CloudWatchLogs_Role")
    end
    
    it 'synthesizes CloudTrail with SNS notifications' do
      synthesizer.instance_eval do
        aws_cloudtrail(:notifying_trail, {
          name: "notifying-trail",
          s3_bucket_name: "notifying-bucket",
          sns_topic_name: "cloudtrail-notifications"
        })
      end
      
      result = synthesizer.synthesis
      trail = result[:resource][:aws_cloudtrail][:notifying_trail]
      
      expect(trail[:sns_topic_name]).to eq("cloudtrail-notifications")
    end
    
    it 'synthesizes CloudTrail with S3 data event selectors' do
      synthesizer.instance_eval do
        aws_cloudtrail(:s3_data_trail, {
          name: "s3-data-trail",
          s3_bucket_name: "s3-data-bucket",
          event_selector: [
            {
              read_write_type: "All",
              include_management_events: false,
              data_resource: [
                {
                  type: "AWS::S3::Object",
                  values: ["arn:aws:s3:::my-bucket/*", "arn:aws:s3:::other-bucket/*"]
                }
              ]
            }
          ]
        })
      end
      
      result = synthesizer.synthesis
      trail = result[:resource][:aws_cloudtrail][:s3_data_trail]
      
      expect(trail).to have_key(:event_selector)
    end
    
    it 'synthesizes CloudTrail with Lambda data event selectors' do
      synthesizer.instance_eval do
        aws_cloudtrail(:lambda_data_trail, {
          name: "lambda-data-trail",
          s3_bucket_name: "lambda-data-bucket",
          event_selector: [
            {
              read_write_type: "WriteOnly",
              include_management_events: true,
              data_resource: [
                {
                  type: "AWS::Lambda::Function",
                  values: ["arn:aws:lambda:us-east-1:123456789012:function:my-function"]
                }
              ]
            }
          ]
        })
      end
      
      result = synthesizer.synthesis
      trail = result[:resource][:aws_cloudtrail][:lambda_data_trail]
      
      expect(trail).to have_key(:event_selector)
    end
    
    it 'synthesizes CloudTrail with mixed data event selectors' do
      synthesizer.instance_eval do
        aws_cloudtrail(:mixed_data_trail, {
          name: "mixed-data-trail",
          s3_bucket_name: "mixed-data-bucket",
          event_selector: [
            {
              read_write_type: "All",
              include_management_events: false,
              data_resource: [
                {
                  type: "AWS::S3::Object",
                  values: ["arn:aws:s3:::s3-bucket/*"]
                },
                {
                  type: "AWS::Lambda::Function",
                  values: ["arn:aws:lambda:us-east-1:123456789012:function:*"]
                }
              ]
            }
          ]
        })
      end
      
      result = synthesizer.synthesis
      trail = result[:resource][:aws_cloudtrail][:mixed_data_trail]
      
      expect(trail).to have_key(:event_selector)
    end
    
    it 'synthesizes CloudTrail with insight selectors' do
      synthesizer.instance_eval do
        aws_cloudtrail(:insights_trail, {
          name: "insights-trail",
          s3_bucket_name: "insights-bucket",
          insight_selector: [
            { insight_type: "ApiCallRateInsight" },
            { insight_type: "ApiErrorRateInsight" }
          ]
        })
      end
      
      result = synthesizer.synthesis
      trail = result[:resource][:aws_cloudtrail][:insights_trail]
      
      expect(trail).to have_key(:insight_selector)
    end
    
    it 'synthesizes single region CloudTrail' do
      synthesizer.instance_eval do
        aws_cloudtrail(:single_region, {
          name: "single-region-trail",
          s3_bucket_name: "single-region-bucket",
          is_multi_region_trail: false,
          include_global_service_events: false
        })
      end
      
      result = synthesizer.synthesis
      trail = result[:resource][:aws_cloudtrail][:single_region]
      
      expect(trail[:is_multi_region_trail]).to be false
      expect(trail[:include_global_service_events]).to be false
    end
    
    it 'synthesizes CloudTrail with custom S3 key prefix' do
      synthesizer.instance_eval do
        aws_cloudtrail(:custom_prefix, {
          name: "custom-prefix-trail",
          s3_bucket_name: "custom-prefix-bucket",
          s3_key_prefix: "audit-logs/cloudtrail"
        })
      end
      
      result = synthesizer.synthesis
      trail = result[:resource][:aws_cloudtrail][:custom_prefix]
      
      expect(trail[:s3_key_prefix]).to eq("audit-logs/cloudtrail")
    end
    
    it 'synthesizes CloudTrail with disabled logging' do
      synthesizer.instance_eval do
        aws_cloudtrail(:disabled_logging, {
          name: "disabled-logging-trail",
          s3_bucket_name: "disabled-logging-bucket",
          enable_logging: false
        })
      end
      
      result = synthesizer.synthesis
      trail = result[:resource][:aws_cloudtrail][:disabled_logging]
      
      expect(trail[:enable_logging]).to be false
    end
    
    it 'synthesizes CloudTrail with disabled log file validation' do
      synthesizer.instance_eval do
        aws_cloudtrail(:no_validation, {
          name: "no-validation-trail",
          s3_bucket_name: "no-validation-bucket",
          enable_log_file_validation: false
        })
      end
      
      result = synthesizer.synthesis
      trail = result[:resource][:aws_cloudtrail][:no_validation]
      
      expect(trail[:enable_log_file_validation]).to be false
    end
    
    it 'synthesizes CloudTrail with tags' do
      synthesizer.instance_eval do
        aws_cloudtrail(:tagged_trail, {
          name: "tagged-trail",
          s3_bucket_name: "tagged-bucket",
          tags: {
            Environment: "production",
            Purpose: "audit",
            Owner: "security-team",
            Compliance: "required"
          }
        })
      end
      
      result = synthesizer.synthesis
      trail = result[:resource][:aws_cloudtrail][:tagged_trail]
      
      expect(trail).to have_key(:tags)
    end
    
    it 'synthesizes compliance-focused CloudTrail' do
      synthesizer.instance_eval do
        aws_cloudtrail(:compliance_trail, {
          name: "compliance-audit-trail",
          s3_bucket_name: "compliance-audit-bucket",
          s3_key_prefix: "compliance-logs",
          kms_key_id: "alias/compliance-audit-key",
          enable_log_file_validation: true,
          is_multi_region_trail: true,
          include_global_service_events: true,
          tags: {
            Purpose: "compliance",
            Type: "audit-trail",
            Compliance: "required"
          }
        })
      end
      
      result = synthesizer.synthesis
      trail = result[:resource][:aws_cloudtrail][:compliance_trail]
      
      expect(trail[:enable_log_file_validation]).to be true
      expect(trail[:is_multi_region_trail]).to be true
      expect(trail[:kms_key_id]).to eq("alias/compliance-audit-key")
    end
    
    it 'synthesizes security monitoring CloudTrail with all features' do
      synthesizer.instance_eval do
        aws_cloudtrail(:security_monitoring, {
          name: "security-monitoring-trail",
          s3_bucket_name: "security-monitoring-bucket",
          s3_key_prefix: "security-logs",
          include_global_service_events: true,
          is_multi_region_trail: true,
          enable_log_file_validation: true,
          kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/security-key-id",
          cloud_watch_logs_group_arn: "arn:aws:logs:us-east-1:123456789012:log-group:/aws/cloudtrail/security",
          cloud_watch_logs_role_arn: "arn:aws:iam::123456789012:role/CloudTrail_Security_Role",
          sns_topic_name: "security-trail-notifications",
          insight_selector: [
            { insight_type: "ApiCallRateInsight" },
            { insight_type: "ApiErrorRateInsight" }
          ],
          event_selector: [
            {
              read_write_type: "All",
              include_management_events: true,
              data_resource: [
                {
                  type: "AWS::S3::Object",
                  values: ["arn:aws:s3:::sensitive-bucket/*"]
                }
              ]
            }
          ],
          tags: {
            Purpose: "security-monitoring",
            Type: "security-trail",
            Monitoring: "enabled"
          }
        })
      end
      
      result = synthesizer.synthesis
      trail = result[:resource][:aws_cloudtrail][:security_monitoring]
      
      expect(trail[:kms_key_id]).to include("arn:aws:kms")
      expect(trail[:cloud_watch_logs_group_arn]).to include("arn:aws:logs")
      expect(trail[:sns_topic_name]).to eq("security-trail-notifications")
      expect(trail).to have_key(:insight_selector)
      expect(trail).to have_key(:event_selector)
    end
    
    it 'handles empty tags gracefully' do
      synthesizer.instance_eval do
        aws_cloudtrail(:no_tags, {
          name: "no-tags-trail",
          s3_bucket_name: "no-tags-bucket",
          tags: {}
        })
      end
      
      result = synthesizer.synthesis
      trail = result[:resource][:aws_cloudtrail][:no_tags]
      
      expect(trail).not_to have_key(:tags)
    end
    
    it 'generates correct JSON for terraform' do
      synthesizer.instance_eval do
        aws_cloudtrail(:json_test, {
          name: "json-test-trail",
          s3_bucket_name: "json-test-bucket",
          kms_key_id: "alias/json-test-key",
          enable_log_file_validation: true,
          tags: {
            Name: "json-test-trail",
            Environment: "testing",
            Purpose: "json-validation"
          }
        })
      end
      
      json_output = JSON.pretty_generate(synthesizer.synthesis)
      parsed = JSON.parse(json_output, symbolize_names: true)
      
      trail = parsed[:resource][:aws_cloudtrail][:json_test]
      expect(trail[:name]).to eq("json-test-trail")
      expect(trail[:s3_bucket_name]).to eq("json-test-bucket")
      expect(trail[:kms_key_id]).to eq("alias/json-test-key")
      expect(trail[:tags]).to be_a(Hash)
      expect(trail[:tags][:Environment]).to eq("testing")
    end
  end
end