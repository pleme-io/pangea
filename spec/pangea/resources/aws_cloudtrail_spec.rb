# frozen_string_literal: true

require 'spec_helper'
require 'pangea/resources/aws_cloudtrail/resource'
require 'pangea/resources/aws_cloudtrail/types'

RSpec.describe 'Pangea::Resources::AWS#aws_cloudtrail' do
  include Pangea::Resources::AWS
  
  let(:mock_terraform_synthesizer) { instance_double(TerraformSynthesizer) }
  let(:mock_synthesis_context) { double('SynthesisContext') }
  
  before do
    allow(TerraformSynthesizer).to receive(:new).and_return(mock_terraform_synthesizer)
    allow(mock_terraform_synthesizer).to receive(:instance_eval)
    allow(mock_terraform_synthesizer).to receive(:synthesis).and_return(mock_synthesis_context)
    
    # Mock the resource method with all necessary methods
    allow(self).to receive(:resource) do |resource_type, name, &block|
      if block_given?
        mock_resource_context = Object.new
        
        # Define all expected methods
        %w[name s3_bucket_name s3_key_prefix include_global_service_events is_multi_region_trail
           enable_logging enable_log_file_validation kms_key_id cloud_watch_logs_group_arn
           cloud_watch_logs_role_arn sns_topic_name event_selector insight_selector tags
           read_write_type include_management_events data_resource type values insight_type].each do |method_name|
          mock_resource_context.define_singleton_method(method_name) { |value = nil, &inner_block| }
        end
        
        mock_resource_context.instance_eval(&block)
      end
    end
  end

  describe '#aws_cloudtrail' do
    context 'with valid attributes' do
      it 'creates a basic CloudTrail' do
        result = aws_cloudtrail(:basic_trail, {
          name: "my-cloudtrail",
          s3_bucket_name: "my-cloudtrail-bucket"
        })
        
        expect(result).to be_a(Pangea::Resources::ResourceReference)
        expect(result.type).to eq('aws_cloudtrail')
        expect(result.name).to eq(:basic_trail)
        expect(result.resource_attributes[:name]).to eq("my-cloudtrail")
        expect(result.resource_attributes[:s3_bucket_name]).to eq("my-cloudtrail-bucket")
      end
      
      it 'creates a trail with encryption' do
        result = aws_cloudtrail(:encrypted_trail, {
          name: "encrypted-trail",
          s3_bucket_name: "encrypted-bucket",
          kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678"
        })
        
        expect(result.has_encryption).to be true
        expect(result.resource_attributes[:kms_key_id]).to include("arn:aws:kms")
      end
      
      it 'creates a trail with CloudWatch integration' do
        result = aws_cloudtrail(:monitored_trail, {
          name: "monitored-trail",
          s3_bucket_name: "monitored-bucket",
          cloud_watch_logs_group_arn: "arn:aws:logs:us-east-1:123456789012:log-group:/aws/cloudtrail",
          cloud_watch_logs_role_arn: "arn:aws:iam::123456789012:role/CloudTrail_CloudWatchLogs_Role"
        })
        
        expect(result.has_cloudwatch_integration).to be true
        expect(result.resource_attributes[:cloud_watch_logs_group_arn]).to include("arn:aws:logs")
        expect(result.resource_attributes[:cloud_watch_logs_role_arn]).to include("arn:aws:iam")
      end
      
      it 'creates a trail with SNS notifications' do
        result = aws_cloudtrail(:notifying_trail, {
          name: "notifying-trail",
          s3_bucket_name: "notifying-bucket",
          sns_topic_name: "cloudtrail-notifications"
        })
        
        expect(result.has_sns_notifications).to be true
        expect(result.resource_attributes[:sns_topic_name]).to eq("cloudtrail-notifications")
      end
      
      it 'creates a trail with event selectors for S3 data events' do
        result = aws_cloudtrail(:s3_data_trail, {
          name: "s3-data-trail",
          s3_bucket_name: "s3-data-bucket",
          event_selector: [
            {
              read_write_type: "All",
              include_management_events: false,
              data_resource: [
                {
                  type: "AWS::S3::Object",
                  values: ["arn:aws:s3:::my-bucket/*"]
                }
              ]
            }
          ]
        })
        
        expect(result.has_event_selectors).to be true
        expect(result.logs_s3_data_events).to be true
        expect(result.tracked_resource_types).to include("AWS::S3::Object")
      end
      
      it 'creates a trail with event selectors for Lambda data events' do
        result = aws_cloudtrail(:lambda_data_trail, {
          name: "lambda-data-trail", 
          s3_bucket_name: "lambda-data-bucket",
          event_selector: [
            {
              read_write_type: "All",
              include_management_events: false,
              data_resource: [
                {
                  type: "AWS::Lambda::Function",
                  values: ["arn:aws:lambda:us-east-1:123456789012:function:*"]
                }
              ]
            }
          ]
        })
        
        expect(result.has_event_selectors).to be true
        expect(result.logs_lambda_data_events).to be true
        expect(result.tracked_resource_types).to include("AWS::Lambda::Function")
      end
      
      it 'creates a trail with insight selectors' do
        result = aws_cloudtrail(:insights_trail, {
          name: "insights-trail",
          s3_bucket_name: "insights-bucket",
          insight_selector: [
            { insight_type: "ApiCallRateInsight" },
            { insight_type: "ApiErrorRateInsight" }
          ]
        })
        
        expect(result.has_insight_selectors).to be true
        expect(result.tracked_insight_types).to include("ApiCallRateInsight", "ApiErrorRateInsight")
      end
      
      it 'creates a compliance trail' do
        result = aws_cloudtrail(:compliance_trail, {
          name: "compliance-trail",
          s3_bucket_name: "compliance-bucket",
          enable_log_file_validation: true,
          kms_key_id: "alias/cloudtrail-key",
          is_multi_region_trail: true
        })
        
        expect(result.is_compliance_trail).to be true
        expect(result.recommended_log_retention_days).to eq(2555) # ~7 years
      end
      
      it 'creates a security monitoring trail' do
        result = aws_cloudtrail(:security_trail, {
          name: "security-trail",
          s3_bucket_name: "security-bucket",
          include_global_service_events: true,
          cloud_watch_logs_group_arn: "arn:aws:logs:us-east-1:123456789012:log-group:/aws/cloudtrail",
          cloud_watch_logs_role_arn: "arn:aws:iam::123456789012:role/CloudTrail_CloudWatchLogs_Role",
          insight_selector: [
            { insight_type: "ApiCallRateInsight" }
          ]
        })
        
        expect(result.is_security_monitoring_trail).to be true
        expect(result.recommended_log_retention_days).to eq(365) # 1 year
      end
      
      it 'returns reference with all terraform outputs' do
        result = aws_cloudtrail(:full_output, {
          name: "full-output-trail",
          s3_bucket_name: "full-output-bucket"
        })
        
        expect(result.id).to eq("${aws_cloudtrail.full_output.id}")
        expect(result.arn).to eq("${aws_cloudtrail.full_output.arn}")
        expect(result.name).to eq("${aws_cloudtrail.full_output.name}")
        expect(result.home_region).to eq("${aws_cloudtrail.full_output.home_region}")
        expect(result.s3_bucket_name).to eq("${aws_cloudtrail.full_output.s3_bucket_name}")
        expect(result.sns_topic_arn).to eq("${aws_cloudtrail.full_output.sns_topic_arn}")
      end
      
      it 'provides computed properties' do
        result = aws_cloudtrail(:computed_props, {
          name: "computed-props-trail",
          s3_bucket_name: "computed-props-bucket",
          kms_key_id: "alias/my-key",
          event_selector: [
            {
              data_resource: [
                { type: "AWS::S3::Object", values: ["arn:aws:s3:::bucket/*"] }
              ]
            }
          ]
        })
        
        expect(result.has_encryption).to be true
        expect(result.has_event_selectors).to be true
        expect(result.estimated_monthly_cost_usd).to be_a(Float)
        expect(result.trail_summary).to include("computed-props-trail")
      end
    end
    
    context 'with invalid attributes' do
      it 'raises error for missing name' do
        expect {
          aws_cloudtrail(:invalid, {
            s3_bucket_name: "bucket"
          })
        }.to raise_error(Dry::Struct::Error, /name is missing/)
      end
      
      it 'raises error for missing s3_bucket_name' do
        expect {
          aws_cloudtrail(:invalid, {
            name: "trail"
          })
        }.to raise_error(Dry::Struct::Error, /s3_bucket_name is missing/)
      end
      
      it 'raises error for invalid trail name length' do
        expect {
          aws_cloudtrail(:invalid, {
            name: "",
            s3_bucket_name: "bucket"
          })
        }.to raise_error(Dry::Struct::Error, /CloudTrail name must be 1-128 characters/)
      end
      
      it 'raises error for trail name too long' do
        expect {
          aws_cloudtrail(:invalid, {
            name: "a" * 129,
            s3_bucket_name: "bucket"
          })
        }.to raise_error(Dry::Struct::Error, /CloudTrail name must be 1-128 characters/)
      end
      
      it 'raises error for invalid trail name characters' do
        expect {
          aws_cloudtrail(:invalid, {
            name: "trail@name",
            s3_bucket_name: "bucket"
          })
        }.to raise_error(Dry::Struct::Error, /CloudTrail name contains invalid characters/)
      end
      
      it 'raises error for partial CloudWatch configuration' do
        expect {
          aws_cloudtrail(:invalid, {
            name: "trail",
            s3_bucket_name: "bucket",
            cloud_watch_logs_group_arn: "arn:aws:logs:us-east-1:123456789012:log-group:/aws/cloudtrail"
          })
        }.to raise_error(Dry::Struct::Error, /Both cloud_watch_logs_group_arn and cloud_watch_logs_role_arn must be provided together/)
      end
      
      it 'raises error for invalid S3 bucket name' do
        expect {
          aws_cloudtrail(:invalid, {
            name: "trail",
            s3_bucket_name: "Bucket-With-Uppercase"
          })
        }.to raise_error(Dry::Struct::Error, /S3 bucket name contains invalid characters/)
      end
    end
  end
  
  describe Pangea::Resources::AWS::EventSelector do
    it 'identifies S3 data events' do
      selector = described_class.new({
        data_resource: [
          { type: "AWS::S3::Object", values: ["arn:aws:s3:::bucket/*"] }
        ]
      })
      
      expect(selector.includes_s3_data_events?).to be true
      expect(selector.includes_lambda_data_events?).to be false
      expect(selector.tracked_resource_types).to include("AWS::S3::Object")
    end
    
    it 'identifies Lambda data events' do
      selector = described_class.new({
        data_resource: [
          { type: "AWS::Lambda::Function", values: ["arn:aws:lambda:*"] }
        ]
      })
      
      expect(selector.includes_lambda_data_events?).to be true
      expect(selector.includes_s3_data_events?).to be false
      expect(selector.tracked_resource_types).to include("AWS::Lambda::Function")
    end
    
    it 'handles mixed resource types' do
      selector = described_class.new({
        data_resource: [
          { type: "AWS::S3::Object", values: ["arn:aws:s3:::bucket/*"] },
          { type: "AWS::Lambda::Function", values: ["arn:aws:lambda:*"] }
        ]
      })
      
      expect(selector.includes_s3_data_events?).to be true
      expect(selector.includes_lambda_data_events?).to be true
      expect(selector.tracked_resource_types).to include("AWS::S3::Object", "AWS::Lambda::Function")
    end
    
    it 'has sensible defaults' do
      selector = described_class.new({})
      
      expect(selector.include_management_events).to be true
      expect(selector.data_resource).to be_empty
      expect(selector.read_write_type).to be_nil
    end
  end
  
  describe Pangea::Resources::AWS::InsightSelector do
    it 'identifies API call rate insights' do
      selector = described_class.new(insight_type: "ApiCallRateInsight")
      
      expect(selector.is_api_call_rate_insight?).to be true
      expect(selector.is_api_error_rate_insight?).to be false
    end
    
    it 'identifies API error rate insights' do
      selector = described_class.new(insight_type: "ApiErrorRateInsight")
      
      expect(selector.is_api_error_rate_insight?).to be true
      expect(selector.is_api_call_rate_insight?).to be false
    end
  end
  
  describe Pangea::Resources::AWS::CloudTrailAttributes do
    describe 'cost estimation' do
      it 'calculates base cost for single region trail' do
        trail = described_class.new({
          name: "trail",
          s3_bucket_name: "bucket",
          is_multi_region_trail: false
        })
        
        expect(trail.estimated_monthly_cost_usd).to eq(2.0)
      end
      
      it 'includes data event costs' do
        trail = described_class.new({
          name: "trail",
          s3_bucket_name: "bucket",
          event_selector: [
            {
              data_resource: [
                { type: "AWS::S3::Object", values: ["arn:aws:s3:::bucket/*"] }
              ]
            }
          ]
        })
        
        expect(trail.estimated_monthly_cost_usd).to be > 0.1
      end
      
      it 'includes CloudWatch costs' do
        trail = described_class.new({
          name: "trail",
          s3_bucket_name: "bucket",
          cloud_watch_logs_group_arn: "arn:aws:logs:us-east-1:123456789012:log-group:/aws/cloudtrail",
          cloud_watch_logs_role_arn: "arn:aws:iam::123456789012:role/CloudTrail_CloudWatchLogs_Role"
        })
        
        expect(trail.estimated_monthly_cost_usd).to be >= 5.0
      end
      
      it 'includes encryption costs' do
        trail = described_class.new({
          name: "trail",
          s3_bucket_name: "bucket",
          kms_key_id: "alias/cloudtrail-key"
        })
        
        expect(trail.estimated_monthly_cost_usd).to be >= 1.0
      end
      
      it 'includes insights costs' do
        trail = described_class.new({
          name: "trail",
          s3_bucket_name: "bucket",
          insight_selector: [
            { insight_type: "ApiCallRateInsight" }
          ]
        })
        
        expect(trail.estimated_monthly_cost_usd).to be >= 3.5
      end
    end
    
    describe 'trail classification' do
      it 'identifies compliance trails' do
        trail = described_class.new({
          name: "compliance-trail",
          s3_bucket_name: "bucket",
          enable_log_file_validation: true,
          kms_key_id: "alias/key",
          is_multi_region_trail: true
        })
        
        expect(trail.is_compliance_trail?).to be true
        expect(trail.recommended_log_retention_days).to eq(2555)
      end
      
      it 'identifies security monitoring trails' do
        trail = described_class.new({
          name: "security-trail",
          s3_bucket_name: "bucket",
          include_global_service_events: true,
          cloud_watch_logs_group_arn: "arn:aws:logs:us-east-1:123456789012:log-group:/aws/cloudtrail",
          cloud_watch_logs_role_arn: "arn:aws:iam::123456789012:role/CloudTrail_CloudWatchLogs_Role",
          insight_selector: [
            { insight_type: "ApiCallRateInsight" }
          ]
        })
        
        expect(trail.is_security_monitoring_trail?).to be true
        expect(trail.recommended_log_retention_days).to eq(365)
      end
    end
    
    describe 'trail summary' do
      it 'generates comprehensive summary' do
        trail = described_class.new({
          name: "full-featured-trail",
          s3_bucket_name: "bucket",
          is_multi_region_trail: true,
          kms_key_id: "alias/key",
          cloud_watch_logs_group_arn: "arn:aws:logs:us-east-1:123456789012:log-group:/aws/cloudtrail",
          cloud_watch_logs_role_arn: "arn:aws:iam::123456789012:role/CloudTrail_CloudWatchLogs_Role",
          event_selector: [
            {
              data_resource: [
                { type: "AWS::S3::Object", values: ["arn:aws:s3:::bucket/*"] }
              ]
            }
          ],
          insight_selector: [
            { insight_type: "ApiCallRateInsight" }
          ],
          enable_log_file_validation: true
        })
        
        summary = trail.trail_summary
        expect(summary).to include("full-featured-trail")
        expect(summary).to include("Multi-region")
        expect(summary).to include("Encrypted")
        expect(summary).to include("CloudWatch")
        expect(summary).to include("Data events")
        expect(summary).to include("Insights")
        expect(summary).to include("Compliance")
      end
    end
  end
  
  describe Pangea::Resources::AWS::CloudTrailConfigs do
    describe '.compliance_trail' do
      it 'provides compliance configuration' do
        config = described_class.compliance_trail(
          trail_name: "compliance-audit",
          s3_bucket: "audit-logs-bucket",
          kms_key: "alias/audit-key"
        )
        
        expect(config[:name]).to eq("compliance-audit")
        expect(config[:s3_bucket_name]).to eq("audit-logs-bucket")
        expect(config[:kms_key_id]).to eq("alias/audit-key")
        expect(config[:is_multi_region_trail]).to be true
        expect(config[:enable_log_file_validation]).to be true
        expect(config[:tags][:Purpose]).to eq("compliance")
      end
    end
    
    describe '.security_monitoring_trail' do
      it 'provides security monitoring configuration' do
        config = described_class.security_monitoring_trail(
          trail_name: "security-monitor",
          s3_bucket: "security-logs-bucket",
          cloudwatch_log_group: "arn:aws:logs:us-east-1:123456789012:log-group:/aws/cloudtrail",
          cloudwatch_role: "arn:aws:iam::123456789012:role/CloudTrail_CloudWatchLogs_Role"
        )
        
        expect(config[:name]).to eq("security-monitor")
        expect(config[:cloud_watch_logs_group_arn]).to include("arn:aws:logs")
        expect(config[:insight_selector]).to have(2).items
        expect(config[:insight_selector].map { |s| s[:insight_type] }).to include("ApiCallRateInsight", "ApiErrorRateInsight")
        expect(config[:tags][:Purpose]).to eq("security-monitoring")
      end
    end
    
    describe '.data_events_trail' do
      it 'provides data events configuration' do
        config = described_class.data_events_trail(
          trail_name: "data-events",
          s3_bucket: "data-events-bucket",
          s3_arns: ["arn:aws:s3:::my-bucket/*"],
          lambda_arns: ["arn:aws:lambda:us-east-1:123456789012:function:my-function"]
        )
        
        expect(config[:name]).to eq("data-events")
        expect(config[:event_selector]).to have(2).items
        expect(config[:include_global_service_events]).to be false
        expect(config[:tags][:Purpose]).to eq("data-events")
      end
    end
    
    describe '.development_trail' do
      it 'provides development configuration' do
        config = described_class.development_trail(
          trail_name: "dev-trail",
          s3_bucket: "dev-logs-bucket"
        )
        
        expect(config[:name]).to eq("dev-trail")
        expect(config[:is_multi_region_trail]).to be false
        expect(config[:enable_log_file_validation]).to be false
        expect(config[:tags][:Environment]).to eq("dev")
      end
    end
  end
end