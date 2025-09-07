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

# Load aws_iam_role_policy_attachment resource and types for testing
require 'pangea/resources/aws_iam_role_policy_attachment/resource'
require 'pangea/resources/aws_iam_role_policy_attachment/types'

RSpec.describe "aws_iam_role_policy_attachment resource function" do
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
  
  describe "IamRolePolicyAttachmentAttributes validation" do
    it "accepts valid role and policy ARN" do
      attrs = Pangea::Resources::AWS::IamRolePolicyAttachmentAttributes.new({
        role: "test-role",
        policy_arn: "arn:aws:iam::aws:policy/ReadOnlyAccess"
      })
      
      expect(attrs.role).to eq("test-role")
      expect(attrs.policy_arn).to eq("arn:aws:iam::aws:policy/ReadOnlyAccess")
    end
    
    it "accepts role ARN instead of name" do
      attrs = Pangea::Resources::AWS::IamRolePolicyAttachmentAttributes.new({
        role: "arn:aws:iam::123456789012:role/test-role",
        policy_arn: "arn:aws:iam::aws:policy/ReadOnlyAccess"
      })
      
      expect(attrs.role).to eq("arn:aws:iam::123456789012:role/test-role")
      expect(attrs.role_specified_by_arn?).to eq(true)
      expect(attrs.role_name).to eq("test-role")
    end
    
    it "validates AWS managed policy ARN format" do
      attrs = Pangea::Resources::AWS::IamRolePolicyAttachmentAttributes.new({
        role: "test-role",
        policy_arn: "arn:aws:iam::aws:policy/AdministratorAccess"
      })
      
      expect(attrs.aws_managed_policy?).to eq(true)
      expect(attrs.customer_managed_policy?).to eq(false)
    end
    
    it "validates customer managed policy ARN format" do
      attrs = Pangea::Resources::AWS::IamRolePolicyAttachmentAttributes.new({
        role: "test-role",
        policy_arn: "arn:aws:iam::123456789012:policy/custom-policy"
      })
      
      expect(attrs.customer_managed_policy?).to eq(true)
      expect(attrs.aws_managed_policy?).to eq(false)
      expect(attrs.policy_account_id).to eq("123456789012")
    end
    
    it "rejects invalid policy ARN format" do
      expect {
        Pangea::Resources::AWS::IamRolePolicyAttachmentAttributes.new({
          role: "test-role",
          policy_arn: "invalid-arn"
        })
      }.to raise_error(Dry::Struct::Error, /must be a valid IAM policy ARN/)
    end
    
    it "rejects invalid role name format" do
      expect {
        Pangea::Resources::AWS::IamRolePolicyAttachmentAttributes.new({
          role: "invalid role name with spaces",
          policy_arn: "arn:aws:iam::aws:policy/ReadOnlyAccess"
        })
      }.to raise_error(Dry::Struct::Error, /must be a valid IAM role name or ARN/)
    end
    
    it "extracts policy name from ARN" do
      attrs = Pangea::Resources::AWS::IamRolePolicyAttachmentAttributes.new({
        role: "test-role",
        policy_arn: "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
      })
      
      expect(attrs.policy_name).to eq("AWSLambdaBasicExecutionRole")
    end
    
    it "generates attachment ID" do
      attrs = Pangea::Resources::AWS::IamRolePolicyAttachmentAttributes.new({
        role: "lambda-execution-role",
        policy_arn: "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
      })
      
      expect(attrs.attachment_id).to eq("lambda-execution-role-AWSLambdaBasicExecutionRole")
    end
    
    it "detects potentially dangerous policies" do
      dangerous_policies = [
        "arn:aws:iam::aws:policy/AdministratorAccess",
        "arn:aws:iam::aws:policy/PowerUserAccess",
        "arn:aws:iam::aws:policy/IAMFullAccess"
      ]
      
      dangerous_policies.each do |policy_arn|
        attrs = Pangea::Resources::AWS::IamRolePolicyAttachmentAttributes.new({
          role: "test-role",
          policy_arn: policy_arn
        })
        
        expect(attrs.potentially_dangerous?).to eq(true)
        expect(attrs.security_risk_level).to eq(:high)
      end
    end
    
    it "categorizes policies correctly" do
      test_cases = {
        "arn:aws:iam::aws:policy/AdministratorAccess" => :administrative,
        "arn:aws:iam::aws:policy/ReadOnlyAccess" => :read_only,
        "arn:aws:iam::aws:policy/PowerUserAccess" => :power_user,
        "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" => :service_linked,
        "arn:aws:iam::aws:policy/AmazonS3FullAccess" => :service_specific,
        "arn:aws:iam::123456789012:policy/custom-policy" => :custom
      }
      
      test_cases.each do |policy_arn, expected_category|
        attrs = Pangea::Resources::AWS::IamRolePolicyAttachmentAttributes.new({
          role: "test-role",
          policy_arn: policy_arn
        })
        
        expect(attrs.policy_category).to eq(expected_category)
      end
    end
    
    it "assesses security risk levels" do
      # High risk - dangerous policy
      attrs1 = Pangea::Resources::AWS::IamRolePolicyAttachmentAttributes.new({
        role: "test-role",
        policy_arn: "arn:aws:iam::aws:policy/AdministratorAccess"
      })
      expect(attrs1.security_risk_level).to eq(:high)
      
      # Low risk - read only AWS managed
      attrs2 = Pangea::Resources::AWS::IamRolePolicyAttachmentAttributes.new({
        role: "test-role",
        policy_arn: "arn:aws:iam::aws:policy/ReadOnlyAccess"
      })
      expect(attrs2.security_risk_level).to eq(:low)
      
      # Medium risk - customer managed (needs review)
      attrs3 = Pangea::Resources::AWS::IamRolePolicyAttachmentAttributes.new({
        role: "test-role",
        policy_arn: "arn:aws:iam::123456789012:policy/custom-policy"
      })
      expect(attrs3.security_risk_level).to eq(:medium)
    end
  end
  
  describe "aws_iam_role_policy_attachment function behavior" do
    it "creates an attachment with role name and AWS managed policy" do
      ref = test_instance.aws_iam_role_policy_attachment(:lambda_basic, {
        role: "lambda-execution-role",
        policy_arn: Pangea::Resources::AWS::AwsManagedPolicies::Lambda::BASIC_EXECUTION_ROLE
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_iam_role_policy_attachment')
      expect(ref.name).to eq(:lambda_basic)
    end
    
    it "creates an attachment with role ARN and customer managed policy" do
      ref = test_instance.aws_iam_role_policy_attachment(:custom_attachment, {
        role: "arn:aws:iam::123456789012:role/cross-account-role",
        policy_arn: "arn:aws:iam::987654321098:policy/shared-policy"
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:role]).to eq("arn:aws:iam::123456789012:role/cross-account-role")
      expect(attrs[:policy_arn]).to eq("arn:aws:iam::987654321098:policy/shared-policy")
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_iam_role_policy_attachment(:test_attachment, {
        role: "test-role",
        policy_arn: "arn:aws:iam::aws:policy/ReadOnlyAccess"
      })
      
      expected_outputs = [:id, :role, :policy_arn]
      
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_iam_role_policy_attachment.test_attachment.")
      end
    end
    
    it "provides computed properties" do
      ref = test_instance.aws_iam_role_policy_attachment(:admin_attachment, {
        role: "admin-role",
        policy_arn: "arn:aws:iam::aws:policy/AdministratorAccess"
      })
      
      expect(ref.aws_managed_policy?).to eq(true)
      expect(ref.customer_managed_policy?).to eq(false)
      expect(ref.policy_name).to eq("AdministratorAccess")
      expect(ref.policy_account_id).to be_nil
      expect(ref.role_name).to eq("admin-role")
      expect(ref.role_specified_by_arn?).to eq(false)
      expect(ref.attachment_id).to eq("admin-role-AdministratorAccess")
      expect(ref.potentially_dangerous?).to eq(true)
      expect(ref.policy_category).to eq(:administrative)
      expect(ref.security_risk_level).to eq(:high)
    end
  end
  
  describe "AwsManagedPolicies module usage" do
    it "provides administrative policies" do
      expect(Pangea::Resources::AWS::AwsManagedPolicies::ADMINISTRATOR_ACCESS).to eq("arn:aws:iam::aws:policy/AdministratorAccess")
      expect(Pangea::Resources::AWS::AwsManagedPolicies::POWER_USER_ACCESS).to eq("arn:aws:iam::aws:policy/PowerUserAccess")
      expect(Pangea::Resources::AWS::AwsManagedPolicies::IAM_FULL_ACCESS).to eq("arn:aws:iam::aws:policy/IAMFullAccess")
    end
    
    it "provides read-only policies" do
      expect(Pangea::Resources::AWS::AwsManagedPolicies::READ_ONLY_ACCESS).to eq("arn:aws:iam::aws:policy/ReadOnlyAccess")
      expect(Pangea::Resources::AWS::AwsManagedPolicies::SECURITY_AUDIT).to eq("arn:aws:iam::aws:policy/SecurityAudit")
    end
    
    it "provides service-specific policies" do
      expect(Pangea::Resources::AWS::AwsManagedPolicies::S3::FULL_ACCESS).to eq("arn:aws:iam::aws:policy/AmazonS3FullAccess")
      expect(Pangea::Resources::AWS::AwsManagedPolicies::Lambda::BASIC_EXECUTION_ROLE).to eq("arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole")
      expect(Pangea::Resources::AWS::AwsManagedPolicies::ECS::TASK_EXECUTION_ROLE).to eq("arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy")
    end
    
    it "provides helper methods for policy organization" do
      admin_policies = Pangea::Resources::AWS::AwsManagedPolicies.administrative_policies
      expect(admin_policies).to include("arn:aws:iam::aws:policy/AdministratorAccess")
      expect(admin_policies).to include("arn:aws:iam::aws:policy/PowerUserAccess")
      
      readonly_policies = Pangea::Resources::AWS::AwsManagedPolicies.read_only_policies
      expect(readonly_policies).to include("arn:aws:iam::aws:policy/ReadOnlyAccess")
      
      service_policies = Pangea::Resources::AWS::AwsManagedPolicies.service_policies
      expect(service_policies).to have_key(:s3)
      expect(service_policies).to have_key(:lambda)
    end
  end
  
  describe "AttachmentPatterns module usage" do
    it "provides Lambda execution role patterns" do
      patterns = Pangea::Resources::AWS::AttachmentPatterns.lambda_execution_role_policies
      expect(patterns).to include("arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole")
      
      vpc_patterns = Pangea::Resources::AWS::AttachmentPatterns.lambda_vpc_execution_role_policies
      expect(vpc_patterns).to include("arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole")
      expect(vpc_patterns).to include("arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole")
    end
    
    it "provides ECS task execution patterns" do
      patterns = Pangea::Resources::AWS::AttachmentPatterns.ecs_task_execution_policies
      expect(patterns).to include("arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy")
    end
    
    it "provides environment-specific patterns" do
      dev_patterns = Pangea::Resources::AWS::AttachmentPatterns.development_policies
      expect(dev_patterns).to include("arn:aws:iam::aws:policy/AmazonS3FullAccess")
      expect(dev_patterns).to include("arn:aws:iam::aws:policy/AWSLambda_FullAccess")
      
      prod_patterns = Pangea::Resources::AWS::AttachmentPatterns.production_read_only_policies
      expect(prod_patterns).to include("arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess")
      expect(prod_patterns).to include("arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess")
    end
    
    it "can be used to create multiple attachments" do
      lambda_policies = Pangea::Resources::AWS::AttachmentPatterns.lambda_execution_role_policies
      attachments = []
      
      lambda_policies.each_with_index do |policy_arn, index|
        ref = test_instance.aws_iam_role_policy_attachment(:"lambda_policy_#{index}", {
          role: "lambda-role",
          policy_arn: policy_arn
        })
        attachments << ref
      end
      
      expect(attachments.length).to eq(lambda_policies.length)
      expect(attachments.all? { |a| a.is_a?(Pangea::Resources::ResourceReference) }).to eq(true)
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_iam_role_policy_attachment(:test_attachment, {
        role: "test-role",
        policy_arn: "arn:aws:iam::aws:policy/ReadOnlyAccess"
      })
      
      expect(ref.outputs[:id]).to eq("${aws_iam_role_policy_attachment.test_attachment.id}")
      expect(ref.outputs[:role]).to eq("${aws_iam_role_policy_attachment.test_attachment.role}")
      expect(ref.outputs[:policy_arn]).to eq("${aws_iam_role_policy_attachment.test_attachment.policy_arn}")
    end
    
    it "can be used with other AWS resources" do
      # Simulate using with IAM role and policy resources
      attachment_ref = test_instance.aws_iam_role_policy_attachment(:app_attachment, {
        role: "app-role",
        policy_arn: "arn:aws:iam::123456789012:policy/app-policy"
      })
      
      # Access attachment properties for other resources
      attachment_id = attachment_ref.attachment_id
      risk_level = attachment_ref.security_risk_level
      
      expect(attachment_id).to eq("app-role-app-policy")
      expect(risk_level).to eq(:medium)
    end
  end
  
  describe "error conditions and edge cases" do
    it "handles string keys in attributes" do
      ref = test_instance.aws_iam_role_policy_attachment(:string_keys, {
        "role" => "string-key-role",
        "policy_arn" => "arn:aws:iam::aws:policy/ReadOnlyAccess"
      })
      
      expect(ref.resource_attributes[:role]).to eq("string-key-role")
      expect(ref.resource_attributes[:policy_arn]).to eq("arn:aws:iam::aws:policy/ReadOnlyAccess")
    end
    
    it "handles cross-account policy attachments" do
      ref = test_instance.aws_iam_role_policy_attachment(:cross_account, {
        role: "arn:aws:iam::111111111111:role/cross-account-role",
        policy_arn: "arn:aws:iam::222222222222:policy/shared-policy"
      })
      
      expect(ref.role_specified_by_arn?).to eq(true)
      expect(ref.role_name).to eq("cross-account-role")
      expect(ref.customer_managed_policy?).to eq(true)
      expect(ref.policy_account_id).to eq("222222222222")
    end
    
    it "handles service-linked role policies" do
      ref = test_instance.aws_iam_role_policy_attachment(:service_linked, {
        role: "AWSServiceRoleForLambda",
        policy_arn: "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
      })
      
      expect(ref.policy_category).to eq(:service_linked)
      expect(ref.aws_managed_policy?).to eq(true)
    end
    
    it "validates role names with special characters" do
      valid_role_names = ["test_role", "test-role", "test.role", "test@role", "test+role", "test,role", "test=role"]
      
      valid_role_names.each do |role_name|
        attrs = Pangea::Resources::AWS::IamRolePolicyAttachmentAttributes.new({
          role: role_name,
          policy_arn: "arn:aws:iam::aws:policy/ReadOnlyAccess"
        })
        expect(attrs.role).to eq(role_name)
      end
    end
  end
  
  describe "security analysis" do
    it "correctly identifies high-risk attachments" do
      high_risk_cases = [
        { role: "admin-role", policy_arn: "arn:aws:iam::aws:policy/AdministratorAccess" },
        { role: "power-role", policy_arn: "arn:aws:iam::aws:policy/PowerUserAccess" },
        { role: "iam-role", policy_arn: "arn:aws:iam::aws:policy/IAMFullAccess" }
      ]
      
      high_risk_cases.each do |attrs|
        ref = test_instance.aws_iam_role_policy_attachment(:high_risk, attrs)
        expect(ref.security_risk_level).to eq(:high)
        expect(ref.potentially_dangerous?).to eq(true)
      end
    end
    
    it "correctly identifies low-risk attachments" do
      low_risk_cases = [
        { role: "viewer-role", policy_arn: "arn:aws:iam::aws:policy/ReadOnlyAccess" },
        { role: "cloudwatch-role", policy_arn: "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess" }
      ]
      
      low_risk_cases.each do |attrs|
        ref = test_instance.aws_iam_role_policy_attachment(:low_risk, attrs)
        expect(ref.security_risk_level).to eq(:low)
        expect(ref.potentially_dangerous?).to eq(false)
      end
    end
    
    it "correctly identifies medium-risk attachments" do
      # Power user policies
      ref1 = test_instance.aws_iam_role_policy_attachment(:medium_risk1, {
        role: "developer-role",
        policy_arn: "arn:aws:iam::aws:policy/PowerUserAccess"
      })
      expect(ref1.security_risk_level).to eq(:high) # PowerUser is actually high risk due to potentially_dangerous?
      
      # Customer managed policies
      ref2 = test_instance.aws_iam_role_policy_attachment(:medium_risk2, {
        role: "app-role",
        policy_arn: "arn:aws:iam::123456789012:policy/custom-policy"
      })
      expect(ref2.security_risk_level).to eq(:medium)
      expect(ref2.potentially_dangerous?).to eq(false)
    end
  end
end