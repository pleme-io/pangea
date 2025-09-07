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

# Load aws_cloudwatch_log_group resource and types for testing
require 'pangea/resources/aws_cloudwatch_log_group/resource'
require 'pangea/resources/aws_cloudwatch_log_group/types'

RSpec.describe "aws_cloudwatch_log_group resource function" do
  # Create a test class that includes the AWS module and mocks terraform-synthesizer
  let(:test_class) do
    Class.new do
      include Pangea::Resources::AWS
      
      # Mock the terraform-synthesizer resource method
      def resource(type, name)
        @resources ||= {}
        resource_data = { type: type, name: name, attributes: {} }
        
        yield if block_given?
        
        @resources["#{type}.#{name}"] = resource_data
        resource_data
      end
      
      # Method missing to capture terraform attributes
      def method_missing(method_name, *args, &block)
        # Don't capture certain methods that might interfere
        return super if [:expect, :be_a, :eq].include?(method_name)
        # For terraform-synthesizer attribute calls, just return the value
        args.first if args.any?
      end
      
      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end
  end
  
  let(:test_instance) { test_class.new }
  
  describe "CloudWatchLogGroupAttributes validation" do
    it "accepts minimal log group configuration" do
      attrs = Pangea::Resources::AWS::Types::CloudWatchLogGroupAttributes.new({
        name: "/aws/lambda/my-function"
      })
      
      expect(attrs.name).to eq("/aws/lambda/my-function")
      expect(attrs.retention_in_days).to be_nil
      expect(attrs.kms_key_id).to be_nil
      expect(attrs.log_group_class).to be_nil
      expect(attrs.skip_destroy).to eq(false)
      expect(attrs.tags).to eq({})
    end
    
    it "accepts complete log group configuration" do
      attrs = Pangea::Resources::AWS::Types::CloudWatchLogGroupAttributes.new({
        name: "/application/api/logs",
        retention_in_days: 30,
        kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
        log_group_class: "INFREQUENT_ACCESS",
        skip_destroy: true,
        tags: {
          Environment: "production",
          Application: "api",
          Team: "backend"
        }
      })
      
      expect(attrs.name).to eq("/application/api/logs")
      expect(attrs.retention_in_days).to eq(30)
      expect(attrs.kms_key_id).to eq("arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012")
      expect(attrs.log_group_class).to eq("INFREQUENT_ACCESS")
      expect(attrs.skip_destroy).to eq(true)
      expect(attrs.tags[:Environment]).to eq("production")
      expect(attrs.tags[:Application]).to eq("api")
    end
    
    it "validates log group name format" do
      # Valid names
      valid_names = [
        "/aws/lambda/function",
        "/application/service/logs",
        "application-logs",
        "/audit/security_logs",
        "simple_log_group",
        "/deeply/nested/service/component/logs",
        "log.group.with.dots"
      ]
      
      valid_names.each do |name|
        expect {
          Pangea::Resources::AWS::Types::CloudWatchLogGroupAttributes.new({ name: name })
        }.not_to raise_error
      end
    end
    
    it "rejects invalid log group names" do
      invalid_names = [
        "",                          # Empty name
        "aws/lambda/function",       # Reserved aws/ prefix (without leading slash)
        "/invalid//double//slash",   # Consecutive slashes
        "/trailing/slash/",          # Trailing slash
        "/invalid space/logs",       # Spaces not allowed
        "/invalid@symbol/logs",      # Invalid characters
        "a" * 513                    # Too long (over 512 chars)
      ]
      
      invalid_names.each do |name|
        expect {
          Pangea::Resources::AWS::Types::CloudWatchLogGroupAttributes.new({ name: name })
        }.to raise_error(Dry::Struct::Error)
      end
    end
    
    it "validates retention period values" do
      valid_retentions = [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, nil]
      
      valid_retentions.each do |retention|
        expect {
          Pangea::Resources::AWS::Types::CloudWatchLogGroupAttributes.new({
            name: "/test/log",
            retention_in_days: retention
          })
        }.not_to raise_error
      end
      
      # Invalid retention periods
      invalid_retentions = [0, 2, 15, 100, 500, 9999]
      
      invalid_retentions.each do |retention|
        expect {
          Pangea::Resources::AWS::Types::CloudWatchLogGroupAttributes.new({
            name: "/test/log",
            retention_in_days: retention
          })
        }.to raise_error(Dry::Types::ConstraintError)
      end
    end
    
    it "validates log group class values" do
      valid_classes = ["STANDARD", "INFREQUENT_ACCESS", nil]
      
      valid_classes.each do |log_class|
        expect {
          Pangea::Resources::AWS::Types::CloudWatchLogGroupAttributes.new({
            name: "/test/log",
            log_group_class: log_class
          })
        }.not_to raise_error
      end
      
      # Invalid log group classes
      expect {
        Pangea::Resources::AWS::Types::CloudWatchLogGroupAttributes.new({
          name: "/test/log",
          log_group_class: "INVALID_CLASS"
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "accepts string keys in attributes hash" do
      attrs = Pangea::Resources::AWS::Types::CloudWatchLogGroupAttributes.new({
        "name" => "/test/log",
        "retention_in_days" => 14,
        "tags" => { "Environment" => "test" }
      })
      
      expect(attrs.name).to eq("/test/log")
      expect(attrs.retention_in_days).to eq(14)
      expect(attrs.tags[:Environment]).to eq("test")
    end
  end
  
  describe "computed properties" do
    let(:basic_attrs) do
      Pangea::Resources::AWS::Types::CloudWatchLogGroupAttributes.new({
        name: "/test/log"
      })
    end
    
    let(:retention_attrs) do
      Pangea::Resources::AWS::Types::CloudWatchLogGroupAttributes.new({
        name: "/test/log",
        retention_in_days: 30
      })
    end
    
    let(:encrypted_attrs) do
      Pangea::Resources::AWS::Types::CloudWatchLogGroupAttributes.new({
        name: "/test/log",
        kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      })
    end
    
    let(:ia_attrs) do
      Pangea::Resources::AWS::Types::CloudWatchLogGroupAttributes.new({
        name: "/test/log",
        log_group_class: "INFREQUENT_ACCESS"
      })
    end
    
    describe "#has_retention?" do
      it "returns false when no retention is set" do
        expect(basic_attrs.has_retention?).to eq(false)
      end
      
      it "returns true when retention is set" do
        expect(retention_attrs.has_retention?).to eq(true)
      end
    end
    
    describe "#has_encryption?" do
      it "returns false when no KMS key is set" do
        expect(basic_attrs.has_encryption?).to eq(false)
      end
      
      it "returns true when KMS key is set" do
        expect(encrypted_attrs.has_encryption?).to eq(true)
      end
    end
    
    describe "#is_infrequent_access?" do
      it "returns false for standard class" do
        expect(basic_attrs.is_infrequent_access?).to eq(false)
      end
      
      it "returns true for infrequent access class" do
        expect(ia_attrs.is_infrequent_access?).to eq(true)
      end
    end
    
    describe "#estimated_monthly_cost_usd" do
      it "calculates cost for standard log group without encryption" do
        cost = basic_attrs.estimated_monthly_cost_usd
        expect(cost).to be_a(Float)
        expect(cost).to eq(5.25) # (10 * 0.50) + (10 * 0.025) + 0
      end
      
      it "calculates cost for standard log group with encryption" do
        cost = encrypted_attrs.estimated_monthly_cost_usd
        expect(cost).to be_a(Float)
        expect(cost).to eq(6.25) # (10 * 0.50) + (10 * 0.025) + 1.0
      end
      
      it "calculates cost for infrequent access log group" do
        cost = ia_attrs.estimated_monthly_cost_usd
        expect(cost).to be_a(Float)
        expect(cost).to eq(2.63) # (10 * 0.25) + (10 * 0.013) + 0
      end
    end
  end
  
  describe "aws_cloudwatch_log_group function" do
    it "creates log group with minimal configuration" do
      result = test_instance.aws_cloudwatch_log_group(:app_logs, {
        name: "/aws/lambda/my-function"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_cloudwatch_log_group')
      expect(result.name).to eq(:app_logs)
      expect(result.resource_attributes[:name]).to eq("/aws/lambda/my-function")
      expect(result.resource_attributes[:skip_destroy]).to eq(false)
      expect(result.resource_attributes[:tags]).to eq({})
    end
    
    it "creates log group with complete configuration" do
      result = test_instance.aws_cloudwatch_log_group(:audit_logs, {
        name: "/audit/security-logs",
        retention_in_days: 365,
        kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
        log_group_class: "STANDARD",
        skip_destroy: true,
        tags: {
          Environment: "production",
          Type: "audit",
          Compliance: "required"
        }
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_cloudwatch_log_group')
      expect(result.name).to eq(:audit_logs)
      expect(result.resource_attributes[:name]).to eq("/audit/security-logs")
      expect(result.resource_attributes[:retention_in_days]).to eq(365)
      expect(result.resource_attributes[:kms_key_id]).to eq("arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012")
      expect(result.resource_attributes[:log_group_class]).to eq("STANDARD")
      expect(result.resource_attributes[:skip_destroy]).to eq(true)
      expect(result.resource_attributes[:tags][:Environment]).to eq("production")
    end
    
    it "creates log group with infrequent access class" do
      result = test_instance.aws_cloudwatch_log_group(:archive_logs, {
        name: "/archive/old-data",
        retention_in_days: 1827,
        log_group_class: "INFREQUENT_ACCESS",
        tags: {
          CostOptimization: "enabled",
          AccessPattern: "infrequent"
        }
      })
      
      expect(result.resource_attributes[:log_group_class]).to eq("INFREQUENT_ACCESS")
      expect(result.is_infrequent_access?).to eq(true)
    end
    
    it "provides correct resource reference outputs" do
      result = test_instance.aws_cloudwatch_log_group(:test_logs, {
        name: "/test/logs"
      })
      
      expected_outputs = {
        id: "${aws_cloudwatch_log_group.test_logs.id}",
        arn: "${aws_cloudwatch_log_group.test_logs.arn}",
        name: "${aws_cloudwatch_log_group.test_logs.name}",
        retention_in_days: "${aws_cloudwatch_log_group.test_logs.retention_in_days}",
        kms_key_id: "${aws_cloudwatch_log_group.test_logs.kms_key_id}",
        log_group_class: "${aws_cloudwatch_log_group.test_logs.log_group_class}",
        tags_all: "${aws_cloudwatch_log_group.test_logs.tags_all}"
      }
      
      expect(result.outputs).to eq(expected_outputs)
    end
    
    it "provides computed properties via method delegation" do
      result = test_instance.aws_cloudwatch_log_group(:computed_test, {
        name: "/test/logs",
        retention_in_days: 14,
        kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
        log_group_class: "INFREQUENT_ACCESS"
      })
      
      expect(result.has_retention?).to eq(true)
      expect(result.has_encryption?).to eq(true)
      expect(result.is_infrequent_access?).to eq(true)
      expect(result.estimated_monthly_cost_usd).to be_a(Float)
      expect(result.estimated_monthly_cost_usd).to eq(3.63) # IA cost + encryption
    end
    
    it "handles lambda function log group naming pattern" do
      result = test_instance.aws_cloudwatch_log_group(:lambda_logs, {
        name: "/aws/lambda/user-management-service",
        retention_in_days: 14,
        tags: {
          Service: "user-management",
          LogType: "function"
        }
      })
      
      expect(result.resource_attributes[:name]).to eq("/aws/lambda/user-management-service")
      expect(result.has_retention?).to eq(true)
    end
    
    it "handles ECS task log group naming pattern" do
      result = test_instance.aws_cloudwatch_log_group(:ecs_logs, {
        name: "/ecs/application-service",
        retention_in_days: 7,
        tags: {
          Service: "application",
          Platform: "ECS",
          LogType: "container"
        }
      })
      
      expect(result.resource_attributes[:name]).to eq("/ecs/application-service")
      expect(result.has_retention?).to eq(true)
    end
    
    it "handles API Gateway log group naming pattern" do
      result = test_instance.aws_cloudwatch_log_group(:apigateway_logs, {
        name: "API-Gateway-Execution-Logs_abcdef123/production",
        retention_in_days: 30,
        tags: {
          Service: "api-gateway",
          Stage: "production",
          LogType: "execution"
        }
      })
      
      expect(result.resource_attributes[:name]).to eq("API-Gateway-Execution-Logs_abcdef123/production")
    end
    
    it "handles custom application log group" do
      result = test_instance.aws_cloudwatch_log_group(:app_logs, {
        name: "/application/web-frontend/access",
        retention_in_days: 90,
        log_group_class: "STANDARD",
        tags: {
          Application: "web-frontend",
          LogType: "access",
          Environment: "production"
        }
      })
      
      expect(result.resource_attributes[:name]).to eq("/application/web-frontend/access")
      expect(result.resource_attributes[:retention_in_days]).to eq(90)
      expect(result.is_infrequent_access?).to eq(false)
    end
    
    it "handles VPC Flow Logs log group" do
      result = test_instance.aws_cloudwatch_log_group(:vpc_flow_logs, {
        name: "/aws/vpc/flowlogs",
        retention_in_days: 7,
        log_group_class: "INFREQUENT_ACCESS",
        tags: {
          LogType: "vpc-flow",
          Environment: "production"
        }
      })
      
      expect(result.resource_attributes[:name]).to eq("/aws/vpc/flowlogs")
      expect(result.is_infrequent_access?).to eq(true)
    end
    
    it "handles audit log group with long retention" do
      result = test_instance.aws_cloudwatch_log_group(:audit_logs, {
        name: "/audit/application-security",
        retention_in_days: 3653, # 10 years
        kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/audit-key",
        skip_destroy: true,
        tags: {
          Type: "audit",
          Compliance: "SOX",
          Retention: "10-years"
        }
      })
      
      expect(result.resource_attributes[:retention_in_days]).to eq(3653)
      expect(result.resource_attributes[:skip_destroy]).to eq(true)
      expect(result.has_encryption?).to eq(true)
    end
    
    it "handles CloudTrail log group" do
      result = test_instance.aws_cloudwatch_log_group(:cloudtrail_logs, {
        name: "/aws/cloudtrail/management-events",
        retention_in_days: 365,
        kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/cloudtrail-key",
        tags: {
          Service: "cloudtrail",
          LogType: "management",
          Compliance: "required"
        }
      })
      
      expect(result.resource_attributes[:name]).to eq("/aws/cloudtrail/management-events")
      expect(result.has_encryption?).to eq(true)
      expect(result.has_retention?).to eq(true)
    end
    
    it "handles container insights log group" do
      result = test_instance.aws_cloudwatch_log_group(:container_insights, {
        name: "/aws/containerinsights/my-cluster/performance",
        retention_in_days: 30,
        tags: {
          Service: "container-insights",
          Cluster: "my-cluster",
          MetricType: "performance"
        }
      })
      
      expect(result.resource_attributes[:name]).to eq("/aws/containerinsights/my-cluster/performance")
    end
    
    it "handles RDS log group" do
      result = test_instance.aws_cloudwatch_log_group(:rds_logs, {
        name: "/aws/rds/instance/mydb/error",
        retention_in_days: 180,
        log_group_class: "STANDARD",
        tags: {
          Service: "rds",
          Database: "mydb",
          LogType: "error"
        }
      })
      
      expect(result.resource_attributes[:name]).to eq("/aws/rds/instance/mydb/error")
      expect(result.resource_attributes[:retention_in_days]).to eq(180)
    end
    
    it "computes cost correctly for different configurations" do
      # Standard without encryption
      standard_log = test_instance.aws_cloudwatch_log_group(:standard, {
        name: "/test/standard",
        log_group_class: "STANDARD"
      })
      expect(standard_log.estimated_monthly_cost_usd).to eq(5.25)
      
      # IA without encryption
      ia_log = test_instance.aws_cloudwatch_log_group(:ia, {
        name: "/test/ia",
        log_group_class: "INFREQUENT_ACCESS"
      })
      expect(ia_log.estimated_monthly_cost_usd).to eq(2.63)
      
      # Standard with encryption
      encrypted_log = test_instance.aws_cloudwatch_log_group(:encrypted, {
        name: "/test/encrypted",
        kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      })
      expect(encrypted_log.estimated_monthly_cost_usd).to eq(6.25)
    end
  end
  
  describe "integration scenarios" do
    it "works with Lambda function logging" do
      # Lambda function would create log group automatically, but we can also create explicitly
      result = test_instance.aws_cloudwatch_log_group(:lambda_explicit, {
        name: "/aws/lambda/data-processor",
        retention_in_days: 14,
        tags: {
          Function: "data-processor",
          Environment: "production"
        }
      })
      
      expect(result.resource_attributes[:name]).to eq("/aws/lambda/data-processor")
    end
    
    it "works with VPC Flow Logs" do
      result = test_instance.aws_cloudwatch_log_group(:flow_logs, {
        name: "/aws/vpc/flowlogs/vpc-12345678",
        retention_in_days: 7,
        log_group_class: "INFREQUENT_ACCESS",
        tags: {
          VpcId: "vpc-12345678",
          LogType: "flow"
        }
      })
      
      expect(result.is_infrequent_access?).to eq(true)
    end
    
    it "works with application logging hierarchy" do
      # Create hierarchical log groups for an application
      access_logs = test_instance.aws_cloudwatch_log_group(:access_logs, {
        name: "/application/web-app/access",
        retention_in_days: 30,
        tags: { LogType: "access" }
      })
      
      error_logs = test_instance.aws_cloudwatch_log_group(:error_logs, {
        name: "/application/web-app/error",
        retention_in_days: 90,
        tags: { LogType: "error" }
      })
      
      debug_logs = test_instance.aws_cloudwatch_log_group(:debug_logs, {
        name: "/application/web-app/debug",
        retention_in_days: 7,
        tags: { LogType: "debug" }
      })
      
      expect(access_logs.resource_attributes[:retention_in_days]).to eq(30)
      expect(error_logs.resource_attributes[:retention_in_days]).to eq(90)
      expect(debug_logs.resource_attributes[:retention_in_days]).to eq(7)
    end
    
    it "works with compliance logging" do
      result = test_instance.aws_cloudwatch_log_group(:compliance_logs, {
        name: "/compliance/financial-transactions",
        retention_in_days: 3653, # 10 years
        kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/compliance-key",
        skip_destroy: true,
        tags: {
          Compliance: "SOX",
          Retention: "10-years",
          Encryption: "required",
          Department: "finance"
        }
      })
      
      expect(result.resource_attributes[:skip_destroy]).to eq(true)
      expect(result.has_encryption?).to eq(true)
      expect(result.has_retention?).to eq(true)
    end
  end
  
  describe "error handling" do
    it "rejects invalid log group name" do
      expect {
        test_instance.aws_cloudwatch_log_group(:invalid, {
          name: "aws/reserved/prefix" # Invalid: missing leading slash and using reserved aws/
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "rejects invalid retention period" do
      expect {
        test_instance.aws_cloudwatch_log_group(:invalid_retention, {
          name: "/test/log",
          retention_in_days: 15 # Invalid: not in AWS-supported list
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "rejects invalid log group class" do
      expect {
        test_instance.aws_cloudwatch_log_group(:invalid_class, {
          name: "/test/log",
          log_group_class: "PREMIUM" # Invalid: not in AWS-supported list
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "rejects empty log group name" do
      expect {
        test_instance.aws_cloudwatch_log_group(:empty_name, {
          name: ""
        })
      }.to raise_error(Dry::Struct::Error, /Log group name cannot be empty/)
    end
    
    it "rejects log group name with consecutive slashes" do
      expect {
        test_instance.aws_cloudwatch_log_group(:double_slash, {
          name: "/invalid//double//slash"
        })
      }.to raise_error(Dry::Struct::Error, /consecutive forward slashes/)
    end
    
    it "rejects log group name with trailing slash" do
      expect {
        test_instance.aws_cloudwatch_log_group(:trailing_slash, {
          name: "/invalid/trailing/"
        })
      }.to raise_error(Dry::Struct::Error, /cannot end with a forward slash/)
    end
    
    it "rejects log group name that is too long" do
      long_name = "a" * 513 # Over 512 character limit
      expect {
        test_instance.aws_cloudwatch_log_group(:too_long, {
          name: long_name
        })
      }.to raise_error(Dry::Struct::Error, /cannot exceed 512 characters/)
    end
    
    it "rejects log group name with invalid characters" do
      expect {
        test_instance.aws_cloudwatch_log_group(:invalid_chars, {
          name: "/invalid space/logs"
        })
      }.to raise_error(Dry::Struct::Error, /can only contain alphanumeric/)
    end
  end
  
  describe "log group naming patterns" do
    it "accepts Lambda function log groups" do
      lambda_patterns = [
        "/aws/lambda/my-function",
        "/aws/lambda/user_service",
        "/aws/lambda/data-processor-v2"
      ]
      
      lambda_patterns.each do |pattern|
        expect {
          test_instance.aws_cloudwatch_log_group(:lambda_test, { name: pattern })
        }.not_to raise_error
      end
    end
    
    it "accepts API Gateway log groups" do
      apigw_patterns = [
        "API-Gateway-Execution-Logs_abcdef123/prod",
        "API-Gateway-Execution-Logs_xyz789/staging",
        "API-Gateway-Access-Logs_rest123/production"
      ]
      
      apigw_patterns.each do |pattern|
        expect {
          test_instance.aws_cloudwatch_log_group(:apigw_test, { name: pattern })
        }.not_to raise_error
      end
    end
    
    it "accepts ECS task log groups" do
      ecs_patterns = [
        "/ecs/web-service",
        "/ecs/api_service",
        "/ecs/background-workers"
      ]
      
      ecs_patterns.each do |pattern|
        expect {
          test_instance.aws_cloudwatch_log_group(:ecs_test, { name: pattern })
        }.not_to raise_error
      end
    end
    
    it "accepts custom application log groups" do
      app_patterns = [
        "/application/frontend/access",
        "/application/backend/error", 
        "/application/database/slow_query",
        "/microservices/user_service/debug",
        "/batch_jobs/data_pipeline/processing"
      ]
      
      app_patterns.each do |pattern|
        expect {
          test_instance.aws_cloudwatch_log_group(:app_test, { name: pattern })
        }.not_to raise_error
      end
    end
  end
  
  describe "retention scenarios" do
    it "handles different retention periods for different log types" do
      # Debug logs - short retention
      debug_log = test_instance.aws_cloudwatch_log_group(:debug, {
        name: "/app/debug",
        retention_in_days: 7
      })
      expect(debug_log.has_retention?).to eq(true)
      expect(debug_log.resource_attributes[:retention_in_days]).to eq(7)
      
      # Access logs - medium retention
      access_log = test_instance.aws_cloudwatch_log_group(:access, {
        name: "/app/access", 
        retention_in_days: 30
      })
      expect(access_log.resource_attributes[:retention_in_days]).to eq(30)
      
      # Audit logs - long retention
      audit_log = test_instance.aws_cloudwatch_log_group(:audit, {
        name: "/audit/transactions",
        retention_in_days: 1827 # 5 years
      })
      expect(audit_log.resource_attributes[:retention_in_days]).to eq(1827)
      
      # Archive logs - maximum retention  
      archive_log = test_instance.aws_cloudwatch_log_group(:archive, {
        name: "/archive/historical",
        retention_in_days: 3653 # ~10 years
      })
      expect(archive_log.resource_attributes[:retention_in_days]).to eq(3653)
    end
    
    it "handles unlimited retention (no retention_in_days)" do
      result = test_instance.aws_cloudwatch_log_group(:unlimited, {
        name: "/critical/permanent-logs",
        skip_destroy: true
      })
      
      expect(result.resource_attributes[:retention_in_days]).to be_nil
      expect(result.has_retention?).to eq(false)
      expect(result.resource_attributes[:skip_destroy]).to eq(true)
    end
  end
  
  describe "encryption scenarios" do
    let(:kms_key_arn) { "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" }
    
    it "handles encrypted log groups" do
      result = test_instance.aws_cloudwatch_log_group(:encrypted, {
        name: "/secure/application-logs",
        kms_key_id: kms_key_arn,
        retention_in_days: 90,
        tags: {
          Encryption: "required",
          Sensitivity: "high"
        }
      })
      
      expect(result.has_encryption?).to eq(true)
      expect(result.resource_attributes[:kms_key_id]).to eq(kms_key_arn)
    end
    
    it "handles unencrypted log groups" do
      result = test_instance.aws_cloudwatch_log_group(:unencrypted, {
        name: "/public/access-logs",
        retention_in_days: 7
      })
      
      expect(result.has_encryption?).to eq(false)
      expect(result.resource_attributes[:kms_key_id]).to be_nil
    end
  end
  
  describe "cost optimization scenarios" do
    it "uses infrequent access for archive logs" do
      result = test_instance.aws_cloudwatch_log_group(:archive_ia, {
        name: "/archive/old-application-logs",
        retention_in_days: 365,
        log_group_class: "INFREQUENT_ACCESS",
        tags: {
          AccessPattern: "infrequent",
          CostOptimization: "enabled"
        }
      })
      
      expect(result.is_infrequent_access?).to eq(true)
      expect(result.estimated_monthly_cost_usd).to eq(2.63) # Lower cost for IA
    end
    
    it "uses standard class for frequently accessed logs" do
      result = test_instance.aws_cloudwatch_log_group(:frequent_access, {
        name: "/application/real-time-logs",
        retention_in_days: 14,
        log_group_class: "STANDARD",
        tags: {
          AccessPattern: "frequent",
          RealTime: "true"
        }
      })
      
      expect(result.is_infrequent_access?).to eq(false)
      expect(result.estimated_monthly_cost_usd).to eq(5.25) # Higher cost but faster access
    end
  end
  
  describe "enterprise logging patterns" do
    it "supports multi-environment logging" do
      environments = ["development", "staging", "production"]
      
      environments.each do |env|
        result = test_instance.aws_cloudwatch_log_group(:"#{env}_logs", {
          name: "/application/web-service/#{env}",
          retention_in_days: env == "production" ? 90 : 14,
          log_group_class: env == "production" ? "STANDARD" : "INFREQUENT_ACCESS",
          tags: {
            Environment: env,
            Service: "web-service"
          }
        })
        
        expect(result.resource_attributes[:name]).to eq("/application/web-service/#{env}")
        expect(result.resource_attributes[:tags][:Environment]).to eq(env)
      end
    end
    
    it "supports microservices logging architecture" do
      services = ["user-service", "order-service", "payment-service", "notification-service"]
      
      services.each do |service|
        result = test_instance.aws_cloudwatch_log_group(:"#{service.gsub('-', '_')}_logs", {
          name: "/microservices/#{service}/application",
          retention_in_days: 30,
          tags: {
            Service: service,
            Architecture: "microservices",
            LogType: "application"
          }
        })
        
        expect(result.resource_attributes[:name]).to eq("/microservices/#{service}/application")
        expect(result.resource_attributes[:tags][:Service]).to eq(service)
      end
    end
    
    it "supports compliance logging with proper governance" do
      result = test_instance.aws_cloudwatch_log_group(:compliance_governed, {
        name: "/compliance/pci-dss/payment-logs",
        retention_in_days: 1827, # 5 years for PCI DSS
        kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/pci-compliance",
        skip_destroy: true,
        tags: {
          Compliance: "PCI-DSS",
          DataClassification: "restricted",
          Owner: "security-team",
          Reviewer: "compliance-officer",
          BusinessJustification: "payment-processing"
        }
      })
      
      expect(result.has_encryption?).to eq(true)
      expect(result.resource_attributes[:skip_destroy]).to eq(true)
      expect(result.resource_attributes[:tags][:Compliance]).to eq("PCI-DSS")
    end
  end
end