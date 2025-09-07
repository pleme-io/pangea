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

# Load aws_lambda_permission resource and types for testing
require 'pangea/resources/aws_lambda_permission/resource'
require 'pangea/resources/aws_lambda_permission/types'

RSpec.describe "aws_lambda_permission resource function" do
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
  let(:function_arn) { "arn:aws:lambda:us-east-1:123456789012:function:my-function" }
  let(:api_execution_arn) { "arn:aws:execute-api:us-east-1:123456789012:abc123/*/*/*" }
  let(:s3_bucket_arn) { "arn:aws:s3:::my-bucket" }
  
  describe "LambdaPermissionAttributes validation" do
    it "accepts basic API Gateway permission configuration" do
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "my-function",
        principal: "apigateway.amazonaws.com",
        source_arn: api_execution_arn,
        statement_id: "AllowAPIGatewayInvoke"
      })
      
      expect(attrs.action).to eq("lambda:InvokeFunction")
      expect(attrs.function_name).to eq("my-function")
      expect(attrs.principal).to eq("apigateway.amazonaws.com")
      expect(attrs.source_arn).to eq(api_execution_arn)
      expect(attrs.statement_id).to eq("AllowAPIGatewayInvoke")
      expect(attrs.is_service_principal?).to eq(true)
      expect(attrs.service_name).to eq("apigateway")
    end
    
    it "accepts S3 trigger permission configuration" do
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: function_arn,
        principal: "s3.amazonaws.com",
        source_arn: s3_bucket_arn,
        source_account: "123456789012"
      })
      
      expect(attrs.principal).to eq("s3.amazonaws.com")
      expect(attrs.source_arn).to eq(s3_bucket_arn)
      expect(attrs.source_account).to eq("123456789012")
      expect(attrs.service_name).to eq("s3")
      expect(attrs.requires_source_arn?).to eq(true)
    end
    
    it "accepts EventBridge rule permission configuration" do
      event_rule_arn = "arn:aws:events:us-east-1:123456789012:rule/my-rule"
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "event-processor",
        principal: "events.amazonaws.com",
        source_arn: event_rule_arn,
        statement_id: "AllowEventBridgeInvoke"
      })
      
      expect(attrs.principal).to eq("events.amazonaws.com")
      expect(attrs.source_arn).to eq(event_rule_arn)
      expect(attrs.service_name).to eq("events")
      expect(attrs.requires_source_arn?).to eq(true)
    end
    
    it "accepts SNS topic permission configuration" do
      sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:my-topic"
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "notification-handler",
        principal: "sns.amazonaws.com",
        source_arn: sns_topic_arn
      })
      
      expect(attrs.principal).to eq("sns.amazonaws.com")
      expect(attrs.source_arn).to eq(sns_topic_arn)
      expect(attrs.service_name).to eq("sns")
    end
    
    it "accepts cross-account permission with account ID" do
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "shared-function",
        principal: "987654321098",
        statement_id: "AllowPartnerAccount"
      })
      
      expect(attrs.principal).to eq("987654321098")
      expect(attrs.is_service_principal?).to eq(false)
      expect(attrs.is_cross_account?).to eq(true)
      expect(attrs.service_name).to be_nil
    end
    
    it "accepts cross-account permission with IAM ARN" do
      iam_role_arn = "arn:aws:iam::987654321098:role/CrossAccountRole"
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "shared-function",
        principal: iam_role_arn,
        statement_id: "AllowSpecificRole"
      })
      
      expect(attrs.principal).to eq(iam_role_arn)
      expect(attrs.is_cross_account?).to eq(true)
      expect(attrs.is_service_principal?).to eq(false)
    end
    
    it "accepts CloudWatch Logs permission configuration" do
      log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/apigateway/my-api"
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "log-processor",
        principal: "logs.amazonaws.com",
        source_arn: log_group_arn
      })
      
      expect(attrs.principal).to eq("logs.amazonaws.com")
      expect(attrs.service_name).to eq("logs")
      expect(attrs.source_arn).to eq(log_group_arn)
    end
    
    it "accepts Cognito trigger permission configuration" do
      user_pool_arn = "arn:aws:cognito-idp:us-east-1:123456789012:userpool/us-east-1_abcdef123"
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "cognito-trigger",
        principal: "cognito-idp.amazonaws.com",
        source_arn: user_pool_arn
      })
      
      expect(attrs.principal).to eq("cognito-idp.amazonaws.com")
      expect(attrs.service_name).to eq("cognito-idp")
      expect(attrs.source_arn).to eq(user_pool_arn)
    end
    
    it "accepts IoT rule permission configuration" do
      iot_rule_arn = "arn:aws:iot:us-east-1:123456789012:rule/my-rule"
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "iot-processor",
        principal: "iot.amazonaws.com",
        source_arn: iot_rule_arn
      })
      
      expect(attrs.principal).to eq("iot.amazonaws.com")
      expect(attrs.service_name).to eq("iot")
      expect(attrs.source_arn).to eq(iot_rule_arn)
    end
    
    it "accepts Lex bot permission configuration" do
      lex_bot_arn = "arn:aws:lex:us-east-1:123456789012:bot/my-bot"
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "lex-fulfillment",
        principal: "lex.amazonaws.com",
        source_arn: lex_bot_arn,
        event_source_token: "unique-token-123"
      })
      
      expect(attrs.principal).to eq("lex.amazonaws.com")
      expect(attrs.source_arn).to eq(lex_bot_arn)
      expect(attrs.event_source_token).to eq("unique-token-123")
      expect(attrs.service_name).to eq("lex")
    end
    
    it "accepts Step Functions permission configuration" do
      state_machine_arn = "arn:aws:states:us-east-1:123456789012:stateMachine:my-state-machine"
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "step-function-task",
        principal: "states.amazonaws.com",
        source_arn: state_machine_arn
      })
      
      expect(attrs.principal).to eq("states.amazonaws.com")
      expect(attrs.service_name).to eq("states")
      expect(attrs.source_arn).to eq(state_machine_arn)
    end
    
    it "accepts ALB function URL permission configuration" do
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "web-function",
        principal: "lambda.alb.amazonaws.com",
        function_url_auth_type: "AWS_IAM"
      })
      
      expect(attrs.principal).to eq("lambda.alb.amazonaws.com")
      expect(attrs.function_url_auth_type).to eq("AWS_IAM")
    end
    
    it "accepts qualifier for version-specific permissions" do
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "versioned-function",
        principal: "apigateway.amazonaws.com",
        qualifier: "LIVE",
        source_arn: api_execution_arn
      })
      
      expect(attrs.qualifier).to eq("LIVE")
    end
    
    it "accepts organizational unit permission" do
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "org-function",
        principal: "123456789012",
        principal_org_id: "ou-root-abcdef123",
        statement_id: "AllowOrgAccess"
      })
      
      expect(attrs.principal_org_id).to eq("ou-root-abcdef123")
      expect(attrs.is_cross_account?).to eq(true)
    end
    
    it "auto-generates statement_id when not provided" do
      # Mock time for consistent testing
      allow(Time).to receive(:now).and_return(Time.at(1234567890))
      
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "auto-id-function",
        principal: "apigateway.amazonaws.com"
      })
      
      expect(attrs.statement_id).to eq("AllowExecutionFrom1234567890")
    end
    
    it "validates action enumeration" do
      expect {
        Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
          action: "lambda:InvalidAction",
          function_name: "test-function",
          principal: "apigateway.amazonaws.com"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates unknown service principal" do
      expect {
        Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
          action: "lambda:InvokeFunction",
          function_name: "test-function",
          principal: "unknown-service.amazonaws.com"
        })
      }.to raise_error(Dry::Struct::Error, /Unknown AWS service principal/)
    end
    
    it "validates invalid principal format" do
      expect {
        Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
          action: "lambda:InvokeFunction",
          function_name: "test-function",
          principal: "invalid-principal-format"
        })
      }.to raise_error(Dry::Struct::Error, /Principal must be/)
    end
    
    it "validates source ARN format" do
      expect {
        Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
          action: "lambda:InvokeFunction",
          function_name: "test-function",
          principal: "apigateway.amazonaws.com",
          source_arn: "invalid-arn-format"
        })
      }.to raise_error(Dry::Struct::Error, /must be a valid AWS ARN/)
    end
    
    it "validates statement ID format" do
      expect {
        Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
          action: "lambda:InvokeFunction",
          function_name: "test-function",
          principal: "apigateway.amazonaws.com",
          statement_id: "Invalid Statement ID!" # spaces and special chars
        })
      }.to raise_error(Dry::Struct::Error, /alphanumeric characters/)
    end
    
    it "validates function URL auth type restrictions" do
      expect {
        Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
          action: "lambda:InvokeFunction",
          function_name: "test-function",
          principal: "apigateway.amazonaws.com", # wrong principal
          function_url_auth_type: "AWS_IAM"
        })
      }.to raise_error(Dry::Struct::Error, /can only be used with ALB principal/)
    end
    
    it "validates source account format" do
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "test-function",
        principal: "s3.amazonaws.com",
        source_arn: s3_bucket_arn,
        source_account: "123456789012"
      })
      
      expect(attrs.source_account).to eq("123456789012")
    end
    
    it "computes service properties correctly" do
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "test-function",
        principal: "s3.amazonaws.com",
        source_arn: s3_bucket_arn
      })
      
      expect(attrs.is_service_principal?).to eq(true)
      expect(attrs.service_name).to eq("s3")
      expect(attrs.is_cross_account?).to eq(false)
      expect(attrs.allows_all_actions?).to eq(false)
      expect(attrs.requires_source_arn?).to eq(true)
    end
    
    it "computes cross-account properties correctly" do
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "shared-function",
        principal: "987654321098"
      })
      
      expect(attrs.is_service_principal?).to eq(false)
      expect(attrs.is_cross_account?).to eq(true)
      expect(attrs.service_name).to be_nil
      expect(attrs.requires_source_arn?).to eq(false)
    end
    
    it "detects wildcard actions" do
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:*",
        function_name: "admin-function",
        principal: "123456789012"
      })
      
      expect(attrs.allows_all_actions?).to eq(true)
    end
  end
  
  describe "aws_lambda_permission function" do
    it "creates basic lambda permission resource reference" do
      result = test_instance.aws_lambda_permission(:api_permission, {
        action: "lambda:InvokeFunction",
        function_name: "api-handler",
        principal: "apigateway.amazonaws.com",
        source_arn: api_execution_arn
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_lambda_permission')
      expect(result.name).to eq(:api_permission)
    end
    
    it "returns permission reference with terraform outputs" do
      result = test_instance.aws_lambda_permission(:s3_permission, {
        action: "lambda:InvokeFunction",
        function_name: function_arn,
        principal: "s3.amazonaws.com",
        source_arn: s3_bucket_arn,
        statement_id: "AllowS3Invoke"
      })
      
      expect(result.id).to eq("${aws_lambda_permission.s3_permission.id}")
      expect(result.statement_id).to eq("${aws_lambda_permission.s3_permission.statement_id}")
    end
    
    it "returns permission reference with computed properties" do
      result = test_instance.aws_lambda_permission(:service_permission, {
        action: "lambda:InvokeFunction",
        function_name: "event-processor",
        principal: "events.amazonaws.com",
        source_arn: "arn:aws:events:us-east-1:123456789012:rule/my-rule"
      })
      
      expect(result.is_service_principal?).to eq(true)
      expect(result.service_name).to eq("events")
      expect(result.is_cross_account?).to eq(false)
      expect(result.allows_all_actions?).to eq(false)
      expect(result.requires_source_arn?).to eq(true)
    end
    
    it "returns cross-account permission reference with computed properties" do
      result = test_instance.aws_lambda_permission(:cross_account_permission, {
        action: "lambda:*",
        function_name: "admin-function",
        principal: "987654321098"
      })
      
      expect(result.is_service_principal?).to eq(false)
      expect(result.is_cross_account?).to eq(true)
      expect(result.allows_all_actions?).to eq(true)
      expect(result.service_name).to be_nil
    end
    
    it "returns ALB function URL permission reference" do
      result = test_instance.aws_lambda_permission(:alb_permission, {
        action: "lambda:InvokeFunction",
        function_name: "web-function",
        principal: "lambda.alb.amazonaws.com",
        function_url_auth_type: "NONE"
      })
      
      expect(result.is_service_principal?).to eq(true)
    end
  end
  
  describe "service principal patterns" do
    let(:valid_service_principals) do
      [
        "apigateway.amazonaws.com",
        "events.amazonaws.com", 
        "s3.amazonaws.com",
        "sns.amazonaws.com",
        "sqs.amazonaws.com",
        "logs.amazonaws.com",
        "cognito-idp.amazonaws.com",
        "elasticloadbalancing.amazonaws.com",
        "iot.amazonaws.com",
        "lex.amazonaws.com",
        "states.amazonaws.com",
        "kafka.amazonaws.com",
        "config.amazonaws.com",
        "backup.amazonaws.com",
        "datasync.amazonaws.com",
        "mediaconvert.amazonaws.com"
      ]
    end
    
    it "accepts all valid service principals" do
      valid_service_principals.each do |service_principal|
        attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
          action: "lambda:InvokeFunction",
          function_name: "test-function",
          principal: service_principal
        })
        
        expect(attrs.principal).to eq(service_principal)
        expect(attrs.is_service_principal?).to eq(true)
        
        expected_service = service_principal.split('.').first
        expect(attrs.service_name).to eq(expected_service)
      end
    end
  end
  
  describe "action patterns" do
    let(:valid_actions) do
      [
        "lambda:InvokeFunction",
        "lambda:GetFunction",
        "lambda:GetFunctionConfiguration",
        "lambda:UpdateFunctionConfiguration",
        "lambda:UpdateFunctionCode",
        "lambda:DeleteFunction",
        "lambda:PublishVersion",
        "lambda:CreateAlias",
        "lambda:UpdateAlias",
        "lambda:DeleteAlias",
        "lambda:GetAlias"
      ]
    end
    
    it "accepts all valid lambda actions" do
      valid_actions.each do |action|
        attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
          action: action,
          function_name: "test-function",
          principal: "apigateway.amazonaws.com"
        })
        
        expect(attrs.action).to eq(action)
        expect(attrs.allows_all_actions?).to eq(false)
      end
    end
    
    it "detects wildcard actions correctly" do
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:*",
        function_name: "admin-function",
        principal: "123456789012"
      })
      
      expect(attrs.allows_all_actions?).to eq(true)
    end
  end
  
  describe "security validation patterns" do
    it "enforces source ARN requirement for security-sensitive services" do
      security_sensitive_services = ["s3", "sns", "events", "config"]
      
      security_sensitive_services.each do |service|
        attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
          action: "lambda:InvokeFunction",
          function_name: "test-function",
          principal: "#{service}.amazonaws.com"
        })
        
        expect(attrs.requires_source_arn?).to eq(true), "Expected #{service} to require source ARN"
      end
    end
    
    it "allows services without source ARN requirement" do
      non_sensitive_services = ["logs", "cognito-idp", "iot", "lex"]
      
      non_sensitive_services.each do |service|
        attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
          action: "lambda:InvokeFunction",
          function_name: "test-function",
          principal: "#{service}.amazonaws.com"
        })
        
        expect(attrs.requires_source_arn?).to eq(false), "Expected #{service} to not require source ARN"
      end
    end
    
    it "properly categorizes account ID principals" do
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "cross-account-function",
        principal: "123456789012"
      })
      
      expect(attrs.is_service_principal?).to eq(false)
      expect(attrs.is_cross_account?).to eq(true)
      expect(attrs.service_name).to be_nil
    end
    
    it "properly categorizes IAM ARN principals" do
      iam_arn = "arn:aws:iam::987654321098:role/LambdaInvokerRole"
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "cross-account-function",
        principal: iam_arn
      })
      
      expect(attrs.is_service_principal?).to eq(false)
      expect(attrs.is_cross_account?).to eq(true)
      expect(attrs.service_name).to be_nil
    end
  end
  
  describe "edge cases and error conditions" do
    it "validates account ID format in principal" do
      ["12345", "1234567890123", "abcdef123456"].each do |invalid_account|
        expect {
          Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
            action: "lambda:InvokeFunction",
            function_name: "test-function",
            principal: invalid_account
          })
        }.to raise_error(Dry::Struct::Error)
      end
    end
    
    it "validates IAM ARN format in principal" do
      invalid_iam_arns = [
        "arn:aws:iam:123456789012:role/MyRole", # missing account separator
        "arn:aws:s3::123456789012:bucket/mybucket", # wrong service
        "not-an-arn-at-all"
      ]
      
      invalid_iam_arns.each do |invalid_arn|
        expect {
          Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
            action: "lambda:InvokeFunction",
            function_name: "test-function", 
            principal: invalid_arn
          })
        }.to raise_error(Dry::Struct::Error)
      end
    end
    
    it "validates function URL auth type enumeration" do
      expect {
        Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
          action: "lambda:InvokeFunction",
          function_name: "web-function",
          principal: "lambda.alb.amazonaws.com",
          function_url_auth_type: "INVALID_AUTH" # not in enum
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "handles empty and nil values appropriately" do
      attrs = Pangea::Resources::AWS::Types::LambdaPermissionAttributes.new({
        action: "lambda:InvokeFunction",
        function_name: "minimal-function",
        principal: "apigateway.amazonaws.com",
        qualifier: nil,
        source_arn: nil
      })
      
      expect(attrs.qualifier).to be_nil
      expect(attrs.source_arn).to be_nil
    end
  end
end