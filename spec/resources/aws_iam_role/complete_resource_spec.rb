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

# Load aws_iam_role resource and types for testing
require 'pangea/resources/aws_iam_role/resource'
require 'pangea/resources/aws_iam_role/types'

RSpec.describe "aws_iam_role resource function" do
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
  
  describe "IamRoleAttributes validation" do
    it "accepts minimal configuration with EC2 trust policy" do
      attrs = Pangea::Resources::AWS::IamRoleAttributes.new({
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service
      })
      
      expect(attrs.path).to eq('/')
      expect(attrs.force_detach_policies).to eq(false)
      expect(attrs.max_session_duration).to eq(3600)
      expect(attrs.inline_policies).to eq({})
      expect(attrs.tags).to eq({})
    end
    
    it "accepts custom role name" do
      attrs = Pangea::Resources::AWS::IamRoleAttributes.new({
        name: "MyCustomRole",
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service
      })
      
      expect(attrs.name).to eq("MyCustomRole")
    end
    
    it "accepts name prefix instead of name" do
      attrs = Pangea::Resources::AWS::IamRoleAttributes.new({
        name_prefix: "my-role-",
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service
      })
      
      expect(attrs.name_prefix).to eq("my-role-")
    end
    
    it "accepts custom path" do
      attrs = Pangea::Resources::AWS::IamRoleAttributes.new({
        path: "/application/web/",
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service
      })
      
      expect(attrs.path).to eq("/application/web/")
    end
    
    it "accepts description" do
      attrs = Pangea::Resources::AWS::IamRoleAttributes.new({
        description: "Role for EC2 instances in web tier",
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service
      })
      
      expect(attrs.description).to eq("Role for EC2 instances in web tier")
    end
    
    it "accepts Lambda trust policy" do
      attrs = Pangea::Resources::AWS::IamRoleAttributes.new({
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.lambda_service
      })
      
      expect(attrs.assume_role_policy[:Statement].first[:Principal][:Service]).to eq("lambda.amazonaws.com")
    end
    
    it "accepts ECS task trust policy" do
      attrs = Pangea::Resources::AWS::IamRoleAttributes.new({
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ecs_task_service
      })
      
      expect(attrs.assume_role_policy[:Statement].first[:Principal][:Service]).to eq("ecs-tasks.amazonaws.com")
    end
    
    it "accepts cross-account trust policy" do
      attrs = Pangea::Resources::AWS::IamRoleAttributes.new({
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.cross_account("123456789012")
      })
      
      expect(attrs.assume_role_policy[:Statement].first[:Principal][:AWS]).to eq("arn:aws:iam::123456789012:root")
    end
    
    it "accepts SAML federated trust policy" do
      attrs = Pangea::Resources::AWS::IamRoleAttributes.new({
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.saml_federated("arn:aws:iam::123456789012:saml-provider/MyProvider")
      })
      
      expect(attrs.assume_role_policy[:Statement].first[:Principal][:Federated]).to include("saml-provider/MyProvider")
      expect(attrs.assume_role_policy[:Statement].first[:Action]).to eq("sts:AssumeRoleWithSAML")
    end
    
    it "accepts custom trust policy" do
      attrs = Pangea::Resources::AWS::IamRoleAttributes.new({
        assume_role_policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Principal: { Service: ["ec2.amazonaws.com", "ecs.amazonaws.com"] },
            Action: "sts:AssumeRole"
          }]
        }
      })
      
      expect(attrs.assume_role_policy[:Statement].first[:Principal][:Service]).to include("ec2.amazonaws.com")
      expect(attrs.assume_role_policy[:Statement].first[:Principal][:Service]).to include("ecs.amazonaws.com")
    end
    
    it "validates name and name_prefix are mutually exclusive" do
      expect {
        Pangea::Resources::AWS::IamRoleAttributes.new({
          name: "MyRole",
          name_prefix: "my-role-",
          assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both 'name' and 'name_prefix'/)
    end
    
    it "validates assume role policy must have statements" do
      expect {
        Pangea::Resources::AWS::IamRoleAttributes.new({
          assume_role_policy: {
            Version: "2012-10-17",
            Statement: []
          }
        })
      }.to raise_error(Dry::Struct::Error, /Assume role policy must have at least one statement/)
    end
    
    it "accepts max session duration within valid range" do
      attrs = Pangea::Resources::AWS::IamRoleAttributes.new({
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service,
        max_session_duration: 7200  # 2 hours
      })
      
      expect(attrs.max_session_duration).to eq(7200)
    end
    
    it "validates max session duration minimum" do
      expect {
        Pangea::Resources::AWS::IamRoleAttributes.new({
          assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service,
          max_session_duration: 3599  # Less than 1 hour
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates max session duration maximum" do
      expect {
        Pangea::Resources::AWS::IamRoleAttributes.new({
          assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service,
          max_session_duration: 43201  # More than 12 hours
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "accepts permissions boundary ARN" do
      attrs = Pangea::Resources::AWS::IamRoleAttributes.new({
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service,
        permissions_boundary: "arn:aws:iam::123456789012:policy/MyBoundary"
      })
      
      expect(attrs.permissions_boundary).to eq("arn:aws:iam::123456789012:policy/MyBoundary")
    end
    
    it "accepts inline policies" do
      attrs = Pangea::Resources::AWS::IamRoleAttributes.new({
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.lambda_service,
        inline_policies: {
          "CloudWatchLogs" => {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
              ],
              Resource: "arn:aws:logs:*:*:*"
            }]
          },
          "S3Access" => {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: "s3:GetObject",
              Resource: "arn:aws:s3:::my-bucket/*"
            }]
          }
        }
      })
      
      expect(attrs.inline_policies.keys).to contain_exactly("CloudWatchLogs", "S3Access")
      expect(attrs.inline_policies["CloudWatchLogs"][:Statement].first[:Action]).to include("logs:CreateLogGroup")
    end
    
    it "accepts tags" do
      attrs = Pangea::Resources::AWS::IamRoleAttributes.new({
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service,
        tags: {
          Name: "WebServerRole",
          Environment: "production",
          Application: "web-app"
        }
      })
      
      expect(attrs.tags[:Name]).to eq("WebServerRole")
      expect(attrs.tags[:Environment]).to eq("production")
      expect(attrs.tags[:Application]).to eq("web-app")
    end
  end
  
  describe "aws_iam_role function behavior" do
    it "creates a resource reference with minimal attributes" do
      ref = test_instance.aws_iam_role(:test, {
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_iam_role')
      expect(ref.name).to eq(:test)
    end
    
    it "creates a role with custom name" do
      ref = test_instance.aws_iam_role(:my_role, {
        name: "MyApplicationRole",
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("MyApplicationRole")
    end
    
    it "creates a role with name prefix" do
      ref = test_instance.aws_iam_role(:my_role, {
        name_prefix: "app-role-",
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.lambda_service
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name_prefix]).to eq("app-role-")
    end
    
    it "creates a role with description and path" do
      ref = test_instance.aws_iam_role(:organized_role, {
        path: "/application/backend/",
        description: "Backend service role for data processing",
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ecs_task_service
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:path]).to eq("/application/backend/")
      expect(attrs[:description]).to eq("Backend service role for data processing")
    end
    
    it "creates a role with inline policies" do
      ref = test_instance.aws_iam_role(:lambda_role, {
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.lambda_service,
        inline_policies: {
          "DynamoDBAccess" => {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: ["dynamodb:GetItem", "dynamodb:PutItem"],
              Resource: "arn:aws:dynamodb:*:*:table/MyTable"
            }]
          }
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:inline_policies]).to have_key("DynamoDBAccess")
    end
    
    it "creates a cross-account role with conditions" do
      ref = test_instance.aws_iam_role(:cross_account, {
        assume_role_policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Principal: { AWS: "arn:aws:iam::987654321098:root" },
            Action: "sts:AssumeRole",
            Condition: {
              StringEquals: { "sts:ExternalId": "unique-external-id" }
            }
          }]
        },
        max_session_duration: 7200,
        tags: {
          TrustedAccount: "987654321098",
          Purpose: "cross-account-access"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:max_session_duration]).to eq(7200)
      expect(attrs[:tags][:TrustedAccount]).to eq("987654321098")
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_iam_role(:test, {
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service
      })
      
      expected_outputs = [:id, :arn, :name, :unique_id, :create_date]
      
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_iam_role.test.")
      end
    end
    
    it "provides computed properties for service roles" do
      ref = test_instance.aws_iam_role(:test, {
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service
      })
      
      expect(ref.service_principal).to eq("ec2.amazonaws.com")
      expect(ref.is_service_role?).to eq(true)
      expect(ref.is_federated_role?).to eq(false)
      expect(ref.trust_policy_type).to eq(:service)
    end
    
    it "provides computed properties for federated roles" do
      ref = test_instance.aws_iam_role(:test, {
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.saml_federated("arn:aws:iam::123456789012:saml-provider/MyProvider")
      })
      
      expect(ref.service_principal).to eq(nil)
      expect(ref.is_service_role?).to eq(false)
      expect(ref.is_federated_role?).to eq(true)
      expect(ref.trust_policy_type).to eq(:federated)
    end
    
    it "provides computed properties for cross-account roles" do
      ref = test_instance.aws_iam_role(:test, {
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.cross_account("123456789012")
      })
      
      expect(ref.service_principal).to eq(nil)
      expect(ref.is_service_role?).to eq(false)
      expect(ref.is_federated_role?).to eq(false)
      expect(ref.trust_policy_type).to eq(:aws_account)
    end
  end
  
  describe "common IAM role patterns" do
    it "creates an EC2 instance profile role" do
      ref = test_instance.aws_iam_role(:ec2_role, {
        name: "EC2InstanceRole",
        description: "Role for EC2 instances to access AWS services",
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service,
        tags: {
          Name: "EC2InstanceRole",
          Type: "instance-profile"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("EC2InstanceRole")
      expect(ref.is_service_role?).to eq(true)
      expect(ref.service_principal).to eq("ec2.amazonaws.com")
    end
    
    it "creates a Lambda execution role with logging permissions" do
      ref = test_instance.aws_iam_role(:lambda_exec, {
        name_prefix: "lambda-function-",
        description: "Lambda function execution role",
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.lambda_service,
        inline_policies: {
          "CloudWatchLogs" => {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
              ],
              Resource: "arn:aws:logs:*:*:*"
            }]
          }
        },
        tags: {
          Type: "lambda-execution",
          ManagedBy: "terraform"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:inline_policies]).to have_key("CloudWatchLogs")
      expect(ref.service_principal).to eq("lambda.amazonaws.com")
    end
    
    it "creates an ECS task execution role" do
      ref = test_instance.aws_iam_role(:ecs_task, {
        name: "ECSTaskExecutionRole",
        path: "/service/ecs/",
        description: "ECS task execution role with ECR and CloudWatch access",
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ecs_task_service,
        tags: {
          Service: "ecs",
          Type: "task-execution"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:path]).to eq("/service/ecs/")
      expect(ref.service_principal).to eq("ecs-tasks.amazonaws.com")
    end
    
    it "creates a cross-account access role with external ID" do
      ref = test_instance.aws_iam_role(:external_access, {
        name: "ExternalAccessRole",
        description: "Allow partner account to access resources",
        assume_role_policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Principal: { AWS: "arn:aws:iam::999888777666:root" },
            Action: "sts:AssumeRole",
            Condition: {
              StringEquals: {
                "sts:ExternalId": "unique-external-id-12345"
              },
              IpAddress: {
                "aws:SourceIp": ["192.168.1.0/24", "10.0.0.0/8"]
              }
            }
          }]
        },
        max_session_duration: 14400,  # 4 hours
        permissions_boundary: "arn:aws:iam::123456789012:policy/ExternalAccessBoundary",
        tags: {
          PartnerAccount: "999888777666",
          AccessType: "external"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:max_session_duration]).to eq(14400)
      expect(attrs[:permissions_boundary]).to include("ExternalAccessBoundary")
    end
    
    it "creates a SAML federated role" do
      ref = test_instance.aws_iam_role(:saml_role, {
        name: "SAMLFederatedRole",
        description: "Role for SAML federated users",
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.saml_federated(
          "arn:aws:iam::123456789012:saml-provider/CompanySAML"
        ),
        max_session_duration: 28800,  # 8 hours
        tags: {
          IdentityProvider: "CompanySAML",
          Type: "federated"
        }
      })
      
      attrs = ref.resource_attributes
      expect(ref.is_federated_role?).to eq(true)
      expect(ref.trust_policy_type).to eq(:federated)
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_iam_role(:test_role, {
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service
      })
      
      expect(ref.outputs[:id]).to eq("${aws_iam_role.test_role.id}")
      expect(ref.outputs[:arn]).to eq("${aws_iam_role.test_role.arn}")
      expect(ref.outputs[:name]).to eq("${aws_iam_role.test_role.name}")
      expect(ref.outputs[:unique_id]).to eq("${aws_iam_role.test_role.unique_id}")
    end
    
    it "can be used with instance profiles" do
      role_ref = test_instance.aws_iam_role(:for_ec2, {
        name: "EC2Role",
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service
      })
      
      # Simulate using role reference in instance profile
      role_name = role_ref.outputs[:name]
      
      expect(role_name).to eq("${aws_iam_role.for_ec2.name}")
    end
    
    it "supports complex cross-resource references" do
      ref = test_instance.aws_iam_role(:cross_ref, {
        name: "${var.application}-${var.environment}-role",
        assume_role_policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Principal: { Service: "${var.service}.amazonaws.com" },
            Action: "sts:AssumeRole"
          }]
        },
        permissions_boundary: "${data.aws_iam_policy.boundary.arn}",
        tags: {
          Name: "${var.application}-role",
          Environment: "${var.environment}"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to include("var.application")
      expect(attrs[:permissions_boundary]).to include("data.aws_iam_policy")
    end
  end
  
  describe "error conditions and edge cases" do
    it "handles default values correctly" do
      ref = test_instance.aws_iam_role(:defaults, {
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:path]).to eq("/")
      expect(attrs[:force_detach_policies]).to eq(false)
      expect(attrs[:max_session_duration]).to eq(3600)
      expect(attrs[:inline_policies]).to eq({})
    end
    
    it "handles string keys in attributes" do
      ref = test_instance.aws_iam_role(:string_keys, {
        "name" => "StringKeyRole",
        "description" => "Role with string keys",
        "assume_role_policy" => Pangea::Resources::AWS::TrustPolicies.lambda_service,
        "tags" => {
          Name: "string-key-role"  # Tags must use symbol keys
        }
      })
      
      expect(ref.resource_attributes[:name]).to eq("StringKeyRole")
      expect(ref.resource_attributes[:description]).to eq("Role with string keys")
      expect(ref.resource_attributes[:tags][:Name]).to eq("string-key-role")
    end
    
    it "handles multiple service principals" do
      ref = test_instance.aws_iam_role(:multi_service, {
        assume_role_policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Principal: { 
              Service: ["ec2.amazonaws.com", "ecs.amazonaws.com", "lambda.amazonaws.com"]
            },
            Action: "sts:AssumeRole"
          }]
        }
      })
      
      # Should return first service principal
      expect(ref.service_principal).to eq("ec2.amazonaws.com")
      expect(ref.is_service_role?).to eq(true)
    end
    
    it "handles complex trust policies with multiple statements" do
      ref = test_instance.aws_iam_role(:complex_trust, {
        assume_role_policy: {
          Version: "2012-10-17",
          Statement: [
            {
              Effect: "Allow",
              Principal: { Service: "ec2.amazonaws.com" },
              Action: "sts:AssumeRole"
            },
            {
              Effect: "Allow",
              Principal: { AWS: "arn:aws:iam::123456789012:user/admin" },
              Action: "sts:AssumeRole",
              Condition: {
                StringEquals: { "sts:ExternalId": "admin-access" }
              }
            }
          ]
        }
      })
      
      expect(ref.is_service_role?).to eq(true)
      expect(ref.service_principal).to eq("ec2.amazonaws.com")
    end
  end
end