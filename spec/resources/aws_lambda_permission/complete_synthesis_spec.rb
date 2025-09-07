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

# Load aws_lambda_permission resource and terraform-synthesizer for testing
require 'pangea/resources/aws_lambda_permission/resource'
require 'terraform_synthesizer'

RSpec.describe "aws_lambda_permission terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  let(:function_arn) { "arn:aws:lambda:us-east-1:123456789012:function:my-function" }
  let(:api_execution_arn) { "arn:aws:execute-api:us-east-1:123456789012:abc123/*/*/*" }
  let(:s3_bucket_arn) { "arn:aws:s3:::my-bucket" }

  # Test API Gateway permission synthesis
  it "synthesizes API Gateway permission correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:api_permission, {
        action: "lambda:InvokeFunction",
        function_name: "api-handler",
        principal: "apigateway.amazonaws.com",
        source_arn: api_execution_arn,
        statement_id: "AllowAPIGatewayInvoke"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "api_permission")
    
    expect(permission_config["action"]).to eq("lambda:InvokeFunction")
    expect(permission_config["function_name"]).to eq("api-handler")
    expect(permission_config["principal"]).to eq("apigateway.amazonaws.com")
    expect(permission_config["source_arn"]).to eq(api_execution_arn)
    expect(permission_config["statement_id"]).to eq("AllowAPIGatewayInvoke")
  end

  # Test S3 trigger permission synthesis
  it "synthesizes S3 trigger permission correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:s3_permission, {
        action: "lambda:InvokeFunction",
        function_name: function_arn,
        principal: "s3.amazonaws.com",
        source_arn: s3_bucket_arn,
        source_account: "123456789012",
        statement_id: "AllowS3BucketInvoke"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "s3_permission")
    
    expect(permission_config["function_name"]).to eq(function_arn)
    expect(permission_config["principal"]).to eq("s3.amazonaws.com")
    expect(permission_config["source_arn"]).to eq(s3_bucket_arn)
    expect(permission_config["source_account"]).to eq("123456789012")
    expect(permission_config["statement_id"]).to eq("AllowS3BucketInvoke")
  end

  # Test EventBridge rule permission synthesis
  it "synthesizes EventBridge rule permission correctly" do
    event_rule_arn = "arn:aws:events:us-east-1:123456789012:rule/scheduled-job"
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:event_permission, {
        action: "lambda:InvokeFunction",
        function_name: "scheduled-processor",
        principal: "events.amazonaws.com",
        source_arn: event_rule_arn,
        statement_id: "AllowEventBridgeInvoke"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "event_permission")
    
    expect(permission_config["function_name"]).to eq("scheduled-processor")
    expect(permission_config["principal"]).to eq("events.amazonaws.com")
    expect(permission_config["source_arn"]).to eq(event_rule_arn)
    expect(permission_config["statement_id"]).to eq("AllowEventBridgeInvoke")
  end

  # Test SNS topic permission synthesis
  it "synthesizes SNS topic permission correctly" do
    sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:notification-topic"
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:sns_permission, {
        action: "lambda:InvokeFunction",
        function_name: "notification-handler",
        principal: "sns.amazonaws.com",
        source_arn: sns_topic_arn
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "sns_permission")
    
    expect(permission_config["function_name"]).to eq("notification-handler")
    expect(permission_config["principal"]).to eq("sns.amazonaws.com")
    expect(permission_config["source_arn"]).to eq(sns_topic_arn)
  end

  # Test cross-account permission synthesis
  it "synthesizes cross-account permission correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:cross_account_permission, {
        action: "lambda:InvokeFunction",
        function_name: "shared-api-function",
        principal: "987654321098",
        statement_id: "AllowPartnerAccount"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "cross_account_permission")
    
    expect(permission_config["function_name"]).to eq("shared-api-function")
    expect(permission_config["principal"]).to eq("987654321098")
    expect(permission_config["statement_id"]).to eq("AllowPartnerAccount")
    expect(permission_config).not_to have_key("source_arn")
  end

  # Test IAM role principal permission synthesis
  it "synthesizes IAM role principal permission correctly" do
    iam_role_arn = "arn:aws:iam::987654321098:role/LambdaInvokerRole"
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:iam_permission, {
        action: "lambda:InvokeFunction",
        function_name: "restricted-function",
        principal: iam_role_arn,
        statement_id: "AllowSpecificRole"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "iam_permission")
    
    expect(permission_config["function_name"]).to eq("restricted-function")
    expect(permission_config["principal"]).to eq(iam_role_arn)
    expect(permission_config["statement_id"]).to eq("AllowSpecificRole")
  end

  # Test versioned function permission synthesis
  it "synthesizes versioned function permission correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:versioned_permission, {
        action: "lambda:InvokeFunction",
        function_name: "versioned-api",
        principal: "apigateway.amazonaws.com",
        qualifier: "LIVE",
        source_arn: api_execution_arn,
        statement_id: "AllowAPIGatewayLiveInvoke"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "versioned_permission")
    
    expect(permission_config["function_name"]).to eq("versioned-api")
    expect(permission_config["qualifier"]).to eq("LIVE")
    expect(permission_config["principal"]).to eq("apigateway.amazonaws.com")
    expect(permission_config["source_arn"]).to eq(api_execution_arn)
  end

  # Test CloudWatch Logs permission synthesis
  it "synthesizes CloudWatch Logs permission correctly" do
    log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/apigateway/my-api"
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:logs_permission, {
        action: "lambda:InvokeFunction",
        function_name: "log-processor",
        principal: "logs.amazonaws.com",
        source_arn: log_group_arn,
        statement_id: "AllowCloudWatchLogsInvoke"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "logs_permission")
    
    expect(permission_config["function_name"]).to eq("log-processor")
    expect(permission_config["principal"]).to eq("logs.amazonaws.com")
    expect(permission_config["source_arn"]).to eq(log_group_arn)
  end

  # Test Cognito trigger permission synthesis
  it "synthesizes Cognito trigger permission correctly" do
    user_pool_arn = "arn:aws:cognito-idp:us-east-1:123456789012:userpool/us-east-1_abcdef123"
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:cognito_permission, {
        action: "lambda:InvokeFunction",
        function_name: "user-verification",
        principal: "cognito-idp.amazonaws.com",
        source_arn: user_pool_arn,
        statement_id: "AllowCognitoTrigger"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "cognito_permission")
    
    expect(permission_config["function_name"]).to eq("user-verification")
    expect(permission_config["principal"]).to eq("cognito-idp.amazonaws.com")
    expect(permission_config["source_arn"]).to eq(user_pool_arn)
  end

  # Test Lex bot permission synthesis
  it "synthesizes Lex bot permission correctly" do
    lex_bot_arn = "arn:aws:lex:us-east-1:123456789012:bot/customer-service"
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:lex_permission, {
        action: "lambda:InvokeFunction",
        function_name: "lex-fulfillment",
        principal: "lex.amazonaws.com",
        source_arn: lex_bot_arn,
        event_source_token: "unique-bot-token-123"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "lex_permission")
    
    expect(permission_config["function_name"]).to eq("lex-fulfillment")
    expect(permission_config["principal"]).to eq("lex.amazonaws.com")
    expect(permission_config["source_arn"]).to eq(lex_bot_arn)
    expect(permission_config["event_source_token"]).to eq("unique-bot-token-123")
  end

  # Test organizational permission synthesis
  it "synthesizes organizational permission correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:org_permission, {
        action: "lambda:InvokeFunction",
        function_name: "org-shared-function",
        principal: "123456789012",
        principal_org_id: "ou-root-abcdef123456",
        statement_id: "AllowOrgMemberAccess"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "org_permission")
    
    expect(permission_config["function_name"]).to eq("org-shared-function")
    expect(permission_config["principal"]).to eq("123456789012")
    expect(permission_config["principal_org_id"]).to eq("ou-root-abcdef123456")
    expect(permission_config["statement_id"]).to eq("AllowOrgMemberAccess")
  end

  # Test ALB function URL permission synthesis
  it "synthesizes ALB function URL permission correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:alb_permission, {
        action: "lambda:InvokeFunction",
        function_name: "web-app-function",
        principal: "lambda.alb.amazonaws.com",
        function_url_auth_type: "AWS_IAM",
        statement_id: "AllowALBInvoke"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "alb_permission")
    
    expect(permission_config["function_name"]).to eq("web-app-function")
    expect(permission_config["principal"]).to eq("lambda.alb.amazonaws.com")
    expect(permission_config["function_url_auth_type"]).to eq("AWS_IAM")
    expect(permission_config["statement_id"]).to eq("AllowALBInvoke")
  end

  # Test Step Functions permission synthesis
  it "synthesizes Step Functions permission correctly" do
    state_machine_arn = "arn:aws:states:us-east-1:123456789012:stateMachine:order-processing"
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:stepfunctions_permission, {
        action: "lambda:InvokeFunction",
        function_name: "order-validator",
        principal: "states.amazonaws.com",
        source_arn: state_machine_arn
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "stepfunctions_permission")
    
    expect(permission_config["function_name"]).to eq("order-validator")
    expect(permission_config["principal"]).to eq("states.amazonaws.com")
    expect(permission_config["source_arn"]).to eq(state_machine_arn)
  end

  # Test IoT rule permission synthesis
  it "synthesizes IoT rule permission correctly" do
    iot_rule_arn = "arn:aws:iot:us-east-1:123456789012:rule/device-telemetry"
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:iot_permission, {
        action: "lambda:InvokeFunction",
        function_name: "iot-data-processor",
        principal: "iot.amazonaws.com",
        source_arn: iot_rule_arn,
        statement_id: "AllowIoTRuleInvoke"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "iot_permission")
    
    expect(permission_config["function_name"]).to eq("iot-data-processor")
    expect(permission_config["principal"]).to eq("iot.amazonaws.com")
    expect(permission_config["source_arn"]).to eq(iot_rule_arn)
    expect(permission_config["statement_id"]).to eq("AllowIoTRuleInvoke")
  end

  # Test Config rule permission synthesis
  it "synthesizes Config rule permission correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:config_permission, {
        action: "lambda:InvokeFunction",
        function_name: "compliance-checker",
        principal: "config.amazonaws.com",
        source_account: "123456789012",
        statement_id: "AllowConfigInvoke"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "config_permission")
    
    expect(permission_config["function_name"]).to eq("compliance-checker")
    expect(permission_config["principal"]).to eq("config.amazonaws.com")
    expect(permission_config["source_account"]).to eq("123456789012")
    expect(permission_config["statement_id"]).to eq("AllowConfigInvoke")
  end

  # Test minimal permission synthesis (only required fields)
  it "synthesizes minimal permission without optional fields" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:minimal_permission, {
        action: "lambda:InvokeFunction",
        function_name: "basic-function",
        principal: "apigateway.amazonaws.com"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "minimal_permission")
    
    # Required fields should be present
    expect(permission_config["action"]).to eq("lambda:InvokeFunction")
    expect(permission_config["function_name"]).to eq("basic-function")
    expect(permission_config["principal"]).to eq("apigateway.amazonaws.com")
    expect(permission_config["statement_id"]).to start_with("AllowExecutionFrom")
    
    # Optional fields should not be present when not specified
    expect(permission_config).not_to have_key("qualifier")
    expect(permission_config).not_to have_key("source_arn")
    expect(permission_config).not_to have_key("source_account")
    expect(permission_config).not_to have_key("event_source_token")
    expect(permission_config).not_to have_key("principal_org_id")
    expect(permission_config).not_to have_key("function_url_auth_type")
  end

  # Test SQS queue permission synthesis
  it "synthesizes SQS queue permission correctly" do
    sqs_queue_arn = "arn:aws:sqs:us-east-1:123456789012:processing-queue"
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:sqs_permission, {
        action: "lambda:InvokeFunction",
        function_name: "queue-processor",
        principal: "sqs.amazonaws.com",
        source_arn: sqs_queue_arn,
        statement_id: "AllowSQSInvoke"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "sqs_permission")
    
    expect(permission_config["function_name"]).to eq("queue-processor")
    expect(permission_config["principal"]).to eq("sqs.amazonaws.com")
    expect(permission_config["source_arn"]).to eq(sqs_queue_arn)
  end

  # Test ALB target group permission synthesis
  it "synthesizes ALB target group permission correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:alb_target_permission, {
        action: "lambda:InvokeFunction",
        function_name: "web-backend",
        principal: "elasticloadbalancing.amazonaws.com",
        statement_id: "AllowALBInvoke"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "alb_target_permission")
    
    expect(permission_config["function_name"]).to eq("web-backend")
    expect(permission_config["principal"]).to eq("elasticloadbalancing.amazonaws.com")
    expect(permission_config["statement_id"]).to eq("AllowALBInvoke")
  end

  # Test MSK (Kafka) permission synthesis
  it "synthesizes MSK permission correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:kafka_permission, {
        action: "lambda:InvokeFunction",
        function_name: "kafka-consumer",
        principal: "kafka.amazonaws.com",
        statement_id: "AllowMSKInvoke"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "kafka_permission")
    
    expect(permission_config["function_name"]).to eq("kafka-consumer")
    expect(permission_config["principal"]).to eq("kafka.amazonaws.com")
    expect(permission_config["statement_id"]).to eq("AllowMSKInvoke")
  end

  # Test wildcard action permission synthesis
  it "synthesizes wildcard action permission correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:admin_permission, {
        action: "lambda:*",
        function_name: "admin-function",
        principal: "123456789012",
        statement_id: "AllowFullAdminAccess"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "admin_permission")
    
    expect(permission_config["action"]).to eq("lambda:*")
    expect(permission_config["function_name"]).to eq("admin-function")
    expect(permission_config["principal"]).to eq("123456789012")
    expect(permission_config["statement_id"]).to eq("AllowFullAdminAccess")
  end

  # Test AWS Backup permission synthesis
  it "synthesizes AWS Backup permission correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:backup_permission, {
        action: "lambda:InvokeFunction",
        function_name: "backup-notification",
        principal: "backup.amazonaws.com",
        statement_id: "AllowBackupServiceInvoke"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "backup_permission")
    
    expect(permission_config["function_name"]).to eq("backup-notification")
    expect(permission_config["principal"]).to eq("backup.amazonaws.com")
    expect(permission_config["statement_id"]).to eq("AllowBackupServiceInvoke")
  end

  # Test MediaConvert job permission synthesis
  it "synthesizes MediaConvert permission correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_lambda_permission(:mediaconvert_permission, {
        action: "lambda:InvokeFunction",
        function_name: "video-processor",
        principal: "mediaconvert.amazonaws.com",
        statement_id: "AllowMediaConvertInvoke"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    permission_config = json_output.dig("resource", "aws_lambda_permission", "mediaconvert_permission")
    
    expect(permission_config["function_name"]).to eq("video-processor")
    expect(permission_config["principal"]).to eq("mediaconvert.amazonaws.com")
    expect(permission_config["statement_id"]).to eq("AllowMediaConvertInvoke")
  end
end