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
require 'json'

# Load aws_cloudwatch_log_group resource and terraform-synthesizer for testing
require 'pangea/resources/aws_cloudwatch_log_group/resource'
require 'terraform_synthesizer'

RSpec.describe "aws_cloudwatch_log_group terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }

  # Test minimal log group synthesis
  it "synthesizes minimal log group correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:app_logs, {
        name: "/aws/lambda/my-function"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "app_logs")
    
    expect(log_group_config["name"]).to eq("/aws/lambda/my-function")
    expect(log_group_config["skip_destroy"]).to eq(false)
    expect(log_group_config).not_to have_key("retention_in_days")
    expect(log_group_config).not_to have_key("kms_key_id")
    expect(log_group_config).not_to have_key("log_group_class")
  end

  # Test log group with retention synthesis
  it "synthesizes log group with retention correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:api_logs, {
        name: "/application/api/access",
        retention_in_days: 30
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "api_logs")
    
    expect(log_group_config["name"]).to eq("/application/api/access")
    expect(log_group_config["retention_in_days"]).to eq(30)
    expect(log_group_config["skip_destroy"]).to eq(false)
  end

  # Test encrypted log group synthesis
  it "synthesizes encrypted log group correctly" do
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:secure_logs, {
        name: "/secure/audit-logs",
        retention_in_days: 365,
        kms_key_id: kms_key_arn
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "secure_logs")
    
    expect(log_group_config["name"]).to eq("/secure/audit-logs")
    expect(log_group_config["retention_in_days"]).to eq(365)
    expect(log_group_config["kms_key_id"]).to eq(kms_key_arn)
    expect(log_group_config["skip_destroy"]).to eq(false)
  end

  # Test infrequent access log group synthesis
  it "synthesizes infrequent access log group correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:archive_logs, {
        name: "/archive/old-data",
        retention_in_days: 1827,
        log_group_class: "INFREQUENT_ACCESS"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "archive_logs")
    
    expect(log_group_config["name"]).to eq("/archive/old-data")
    expect(log_group_config["retention_in_days"]).to eq(1827)
    expect(log_group_config["log_group_class"]).to eq("INFREQUENT_ACCESS")
    expect(log_group_config["skip_destroy"]).to eq(false)
  end

  # Test log group with skip_destroy synthesis
  it "synthesizes log group with skip_destroy correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:critical_logs, {
        name: "/critical/system-logs",
        retention_in_days: 3653,
        skip_destroy: true
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "critical_logs")
    
    expect(log_group_config["name"]).to eq("/critical/system-logs")
    expect(log_group_config["retention_in_days"]).to eq(3653)
    expect(log_group_config["skip_destroy"]).to eq(true)
  end

  # Test log group with tags synthesis
  it "synthesizes log group with tags correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:tagged_logs, {
        name: "/application/web-service",
        retention_in_days: 14,
        tags: {
          Environment: "production",
          Application: "web-service",
          Team: "backend",
          CostCenter: "engineering"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "tagged_logs")
    
    expect(log_group_config["name"]).to eq("/application/web-service")
    expect(log_group_config["retention_in_days"]).to eq(14)
    
    # Check tags block
    tags_config = log_group_config["tags"]
    expect(tags_config).not_to be_nil
    expect(tags_config["Environment"]).to eq("production")
    expect(tags_config["Application"]).to eq("web-service")
    expect(tags_config["Team"]).to eq("backend")
    expect(tags_config["CostCenter"]).to eq("engineering")
  end

  # Test comprehensive log group with all options
  it "synthesizes comprehensive log group correctly" do
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/comprehensive-key"
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:comprehensive, {
        name: "/comprehensive/test-logs",
        retention_in_days: 90,
        kms_key_id: kms_key_arn,
        log_group_class: "STANDARD",
        skip_destroy: true,
        tags: {
          Environment: "production",
          Service: "comprehensive-test",
          Encryption: "enabled",
          Retention: "90-days"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "comprehensive")
    
    expect(log_group_config["name"]).to eq("/comprehensive/test-logs")
    expect(log_group_config["retention_in_days"]).to eq(90)
    expect(log_group_config["kms_key_id"]).to eq(kms_key_arn)
    expect(log_group_config["log_group_class"]).to eq("STANDARD")
    expect(log_group_config["skip_destroy"]).to eq(true)
    
    # Check tags
    tags_config = log_group_config["tags"]
    expect(tags_config).not_to be_nil
    expect(tags_config["Environment"]).to eq("production")
    expect(tags_config["Service"]).to eq("comprehensive-test")
    expect(tags_config["Encryption"]).to eq("enabled")
    expect(tags_config["Retention"]).to eq("90-days")
  end

  # Test Lambda function log group synthesis
  it "synthesizes Lambda function log group correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:lambda_logs, {
        name: "/aws/lambda/data-processor",
        retention_in_days: 14,
        tags: {
          Function: "data-processor",
          Environment: "production",
          LogType: "function"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "lambda_logs")
    
    expect(log_group_config["name"]).to eq("/aws/lambda/data-processor")
    expect(log_group_config["retention_in_days"]).to eq(14)
    
    tags_config = log_group_config["tags"]
    expect(tags_config["Function"]).to eq("data-processor")
    expect(tags_config["Environment"]).to eq("production")
    expect(tags_config["LogType"]).to eq("function")
  end

  # Test ECS service log group synthesis
  it "synthesizes ECS service log group correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:ecs_logs, {
        name: "/ecs/web-service",
        retention_in_days: 30,
        log_group_class: "STANDARD",
        tags: {
          Service: "web-service",
          Platform: "ECS",
          LogType: "container"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "ecs_logs")
    
    expect(log_group_config["name"]).to eq("/ecs/web-service")
    expect(log_group_config["retention_in_days"]).to eq(30)
    expect(log_group_config["log_group_class"]).to eq("STANDARD")
    
    tags_config = log_group_config["tags"]
    expect(tags_config["Service"]).to eq("web-service")
    expect(tags_config["Platform"]).to eq("ECS")
    expect(tags_config["LogType"]).to eq("container")
  end

  # Test API Gateway log group synthesis
  it "synthesizes API Gateway log group correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:apigw_logs, {
        name: "API-Gateway-Execution-Logs_abcdef123/production",
        retention_in_days: 30,
        tags: {
          Service: "api-gateway",
          Stage: "production",
          LogType: "execution"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "apigw_logs")
    
    expect(log_group_config["name"]).to eq("API-Gateway-Execution-Logs_abcdef123/production")
    expect(log_group_config["retention_in_days"]).to eq(30)
    
    tags_config = log_group_config["tags"]
    expect(tags_config["Service"]).to eq("api-gateway")
    expect(tags_config["Stage"]).to eq("production")
    expect(tags_config["LogType"]).to eq("execution")
  end

  # Test VPC Flow Logs log group synthesis
  it "synthesizes VPC Flow Logs log group correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:vpc_flow_logs, {
        name: "/aws/vpc/flowlogs",
        retention_in_days: 7,
        log_group_class: "INFREQUENT_ACCESS",
        tags: {
          LogType: "vpc-flow",
          Environment: "production"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "vpc_flow_logs")
    
    expect(log_group_config["name"]).to eq("/aws/vpc/flowlogs")
    expect(log_group_config["retention_in_days"]).to eq(7)
    expect(log_group_config["log_group_class"]).to eq("INFREQUENT_ACCESS")
    
    tags_config = log_group_config["tags"]
    expect(tags_config["LogType"]).to eq("vpc-flow")
    expect(tags_config["Environment"]).to eq("production")
  end

  # Test audit log group synthesis with compliance features
  it "synthesizes audit log group with compliance features correctly" do
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/audit-compliance"
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:audit_logs, {
        name: "/audit/financial-transactions",
        retention_in_days: 3653, # 10 years
        kms_key_id: kms_key_arn,
        log_group_class: "STANDARD",
        skip_destroy: true,
        tags: {
          Compliance: "SOX",
          DataClassification: "confidential",
          Retention: "10-years",
          Department: "finance"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "audit_logs")
    
    expect(log_group_config["name"]).to eq("/audit/financial-transactions")
    expect(log_group_config["retention_in_days"]).to eq(3653)
    expect(log_group_config["kms_key_id"]).to eq(kms_key_arn)
    expect(log_group_config["log_group_class"]).to eq("STANDARD")
    expect(log_group_config["skip_destroy"]).to eq(true)
    
    tags_config = log_group_config["tags"]
    expect(tags_config["Compliance"]).to eq("SOX")
    expect(tags_config["DataClassification"]).to eq("confidential")
    expect(tags_config["Retention"]).to eq("10-years")
    expect(tags_config["Department"]).to eq("finance")
  end

  # Test microservices log group synthesis
  it "synthesizes microservices log group correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:user_service_logs, {
        name: "/microservices/user-service/application",
        retention_in_days: 30,
        log_group_class: "STANDARD",
        tags: {
          Service: "user-service",
          Architecture: "microservices",
          LogType: "application",
          Environment: "production"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "user_service_logs")
    
    expect(log_group_config["name"]).to eq("/microservices/user-service/application")
    expect(log_group_config["retention_in_days"]).to eq(30)
    expect(log_group_config["log_group_class"]).to eq("STANDARD")
    
    tags_config = log_group_config["tags"]
    expect(tags_config["Service"]).to eq("user-service")
    expect(tags_config["Architecture"]).to eq("microservices")
    expect(tags_config["LogType"]).to eq("application")
    expect(tags_config["Environment"]).to eq("production")
  end

  # Test log group without tags (empty tags block should not appear)
  it "synthesizes log group without tags correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:no_tags, {
        name: "/simple/logs",
        retention_in_days: 7
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "no_tags")
    
    expect(log_group_config["name"]).to eq("/simple/logs")
    expect(log_group_config["retention_in_days"]).to eq(7)
    expect(log_group_config).not_to have_key("tags") # Empty tags should not appear
  end

  # Test cost-optimized log group synthesis
  it "synthesizes cost-optimized log group correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:cost_optimized, {
        name: "/cost-optimized/batch-logs",
        retention_in_days: 60,
        log_group_class: "INFREQUENT_ACCESS",
        tags: {
          CostOptimization: "enabled",
          AccessPattern: "infrequent",
          LogType: "batch-processing"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "cost_optimized")
    
    expect(log_group_config["name"]).to eq("/cost-optimized/batch-logs")
    expect(log_group_config["retention_in_days"]).to eq(60)
    expect(log_group_config["log_group_class"]).to eq("INFREQUENT_ACCESS")
    
    tags_config = log_group_config["tags"]
    expect(tags_config["CostOptimization"]).to eq("enabled")
    expect(tags_config["AccessPattern"]).to eq("infrequent")
    expect(tags_config["LogType"]).to eq("batch-processing")
  end

  # Test development log group synthesis with short retention
  it "synthesizes development log group correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:dev_logs, {
        name: "/development/web-app/debug",
        retention_in_days: 3, # Very short for development
        tags: {
          Environment: "development",
          LogType: "debug",
          TemporaryData: "true"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "dev_logs")
    
    expect(log_group_config["name"]).to eq("/development/web-app/debug")
    expect(log_group_config["retention_in_days"]).to eq(3)
    expect(log_group_config["skip_destroy"]).to eq(false) # Development logs can be destroyed
    
    tags_config = log_group_config["tags"]
    expect(tags_config["Environment"]).to eq("development")
    expect(tags_config["LogType"]).to eq("debug")
    expect(tags_config["TemporaryData"]).to eq("true")
  end

  # Test security-focused log group synthesis
  it "synthesizes security log group correctly" do
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/security-logs-key"
    
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:security_logs, {
        name: "/security/auth-events",
        retention_in_days: 365,
        kms_key_id: kms_key_arn,
        log_group_class: "STANDARD",
        skip_destroy: true,
        tags: {
          Security: "critical",
          DataClassification: "restricted",
          LogType: "authentication",
          ComplianceRequired: "true"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "security_logs")
    
    expect(log_group_config["name"]).to eq("/security/auth-events")
    expect(log_group_config["retention_in_days"]).to eq(365)
    expect(log_group_config["kms_key_id"]).to eq(kms_key_arn)
    expect(log_group_config["log_group_class"]).to eq("STANDARD")
    expect(log_group_config["skip_destroy"]).to eq(true)
    
    tags_config = log_group_config["tags"]
    expect(tags_config["Security"]).to eq("critical")
    expect(tags_config["DataClassification"]).to eq("restricted")
    expect(tags_config["LogType"]).to eq("authentication")
    expect(tags_config["ComplianceRequired"]).to eq("true")
  end

  # Test CloudTrail log group synthesis
  it "synthesizes CloudTrail log group correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:cloudtrail_logs, {
        name: "/aws/cloudtrail/management-events",
        retention_in_days: 365,
        kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/cloudtrail-key",
        tags: {
          Service: "cloudtrail",
          EventType: "management",
          Compliance: "required"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "cloudtrail_logs")
    
    expect(log_group_config["name"]).to eq("/aws/cloudtrail/management-events")
    expect(log_group_config["retention_in_days"]).to eq(365)
    expect(log_group_config["kms_key_id"]).to eq("arn:aws:kms:us-east-1:123456789012:key/cloudtrail-key")
    
    tags_config = log_group_config["tags"]
    expect(tags_config["Service"]).to eq("cloudtrail")
    expect(tags_config["EventType"]).to eq("management")
    expect(tags_config["Compliance"]).to eq("required")
  end

  # Test batch processing log group synthesis
  it "synthesizes batch processing log group correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:batch_logs, {
        name: "/batch/data-pipeline/processing",
        retention_in_days: 30,
        log_group_class: "INFREQUENT_ACCESS",
        tags: {
          JobType: "data-pipeline",
          LogType: "batch-processing",
          AccessPattern: "infrequent"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "batch_logs")
    
    expect(log_group_config["name"]).to eq("/batch/data-pipeline/processing")
    expect(log_group_config["retention_in_days"]).to eq(30)
    expect(log_group_config["log_group_class"]).to eq("INFREQUENT_ACCESS")
    
    tags_config = log_group_config["tags"]
    expect(tags_config["JobType"]).to eq("data-pipeline")
    expect(tags_config["LogType"]).to eq("batch-processing")
    expect(tags_config["AccessPattern"]).to eq("infrequent")
  end

  # Test monitoring log group synthesis
  it "synthesizes monitoring log group correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_cloudwatch_log_group(:monitoring_logs, {
        name: "/monitoring/metrics-collector",
        retention_in_days: 14,
        tags: {
          Service: "metrics-collector",
          LogType: "monitoring",
          Environment: "production"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    log_group_config = json_output.dig("resource", "aws_cloudwatch_log_group", "monitoring_logs")
    
    expect(log_group_config["name"]).to eq("/monitoring/metrics-collector")
    expect(log_group_config["retention_in_days"]).to eq(14)
    expect(log_group_config["skip_destroy"]).to eq(false)
    
    tags_config = log_group_config["tags"]
    expect(tags_config["Service"]).to eq("metrics-collector")
    expect(tags_config["LogType"]).to eq("monitoring")
    expect(tags_config["Environment"]).to eq("production")
  end
end