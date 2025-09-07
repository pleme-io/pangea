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

# Load aws_iam_policy resource and types for testing
require 'pangea/resources/aws_iam_policy/resource'
require 'pangea/resources/aws_iam_policy/types'

RSpec.describe "aws_iam_policy resource function" do
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
  
  describe "IamPolicyAttributes validation" do
    it "accepts minimal configuration with required attributes" do
      policy_doc = {
        Version: "2012-10-17",
        Statement: [{
          Effect: "Allow",
          Action: "s3:GetObject",
          Resource: "arn:aws:s3:::my-bucket/*"
        }]
      }
      
      attrs = Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "test-policy",
        policy: policy_doc
      })
      
      expect(attrs.name).to eq("test-policy")
      expect(attrs.path).to eq("/")
      expect(attrs.policy[:Statement].first[:Action]).to eq("s3:GetObject")
    end
    
    it "accepts custom path and description" do
      attrs = Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "test-policy",
        path: "/custom/",
        description: "Test IAM policy",
        policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Action: "s3:ListBucket",
            Resource: "*"
          }]
        }
      })
      
      expect(attrs.path).to eq("/custom/")
      expect(attrs.description).to eq("Test IAM policy")
    end
    
    it "validates policy name length" do
      expect {
        Pangea::Resources::AWS::IamPolicyAttributes.new({
          name: "a" * 129,
          policy: { Version: "2012-10-17", Statement: [] }
        })
      }.to raise_error(Dry::Struct::Error, /cannot exceed 128 characters/)
    end
    
    it "validates path format" do
      expect {
        Pangea::Resources::AWS::IamPolicyAttributes.new({
          name: "test-policy",
          path: "missing-leading-slash",
          policy: { Version: "2012-10-17", Statement: [] }
        })
      }.to raise_error(Dry::Struct::Error, /must start and end with/)
    end
    
    it "validates policy document has statements" do
      expect {
        Pangea::Resources::AWS::IamPolicyAttributes.new({
          name: "test-policy",
          policy: { Version: "2012-10-17", Statement: [] }
        })
      }.to raise_error(Dry::Struct::Error, /must have at least one statement/)
    end
    
    it "validates policy document size" do
      # Create a policy document that exceeds 6144 characters
      large_statement = {
        Effect: "Allow",
        Action: Array.new(100) { |i| "service:Action#{i}" },
        Resource: Array.new(100) { |i| "arn:aws:service:region:account:resource/#{i}" }
      }
      
      expect {
        Pangea::Resources::AWS::IamPolicyAttributes.new({
          name: "test-policy",
          policy: { Version: "2012-10-17", Statement: [large_statement] }
        })
      }.to raise_error(Dry::Struct::Error, /cannot exceed 6144 characters/)
    end
    
    it "detects reserved names" do
      attrs = Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "AWS-test-policy",
        policy: { Version: "2012-10-17", Statement: [{ Effect: "Allow", Action: "s3:*", Resource: "*" }] }
      })
      
      expect(attrs.uses_reserved_name?).to eq(true)
      
      attrs2 = Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "MyAmazonPolicy",
        policy: { Version: "2012-10-17", Statement: [{ Effect: "Allow", Action: "s3:*", Resource: "*" }] }
      })
      
      expect(attrs2.uses_reserved_name?).to eq(true)
    end
    
    it "extracts all actions from policy statements" do
      policy = {
        Version: "2012-10-17",
        Statement: [
          { Effect: "Allow", Action: "s3:GetObject", Resource: "*" },
          { Effect: "Allow", Action: ["s3:PutObject", "s3:DeleteObject"], Resource: "*" },
          { Effect: "Deny", Action: "s3:ListBucket", Resource: "*" }
        ]
      }
      
      attrs = Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "test-policy",
        policy: policy
      })
      
      expect(attrs.all_actions).to contain_exactly("s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket")
    end
    
    it "extracts all resources from policy statements" do
      policy = {
        Version: "2012-10-17",
        Statement: [
          { Effect: "Allow", Action: "s3:*", Resource: "arn:aws:s3:::bucket1/*" },
          { Effect: "Allow", Action: "s3:*", Resource: ["arn:aws:s3:::bucket2/*", "arn:aws:s3:::bucket3/*"] },
          { Effect: "Allow", Action: "s3:*", Resource: "*" }
        ]
      }
      
      attrs = Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "test-policy",
        policy: policy
      })
      
      expect(attrs.all_resources).to contain_exactly(
        "arn:aws:s3:::bucket1/*",
        "arn:aws:s3:::bucket2/*", 
        "arn:aws:s3:::bucket3/*",
        "*"
      )
    end
    
    it "detects wildcard permissions" do
      # Wildcard action
      attrs1 = Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "wildcard-action",
        policy: {
          Version: "2012-10-17",
          Statement: [{ Effect: "Allow", Action: "*", Resource: "arn:aws:s3:::bucket/*" }]
        }
      })
      expect(attrs1.has_wildcard_permissions?).to eq(true)
      
      # Wildcard resource
      attrs2 = Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "wildcard-resource",
        policy: {
          Version: "2012-10-17",
          Statement: [{ Effect: "Allow", Action: "s3:GetObject", Resource: "*" }]
        }
      })
      expect(attrs2.has_wildcard_permissions?).to eq(true)
      
      # No wildcards
      attrs3 = Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "no-wildcards",
        policy: {
          Version: "2012-10-17",
          Statement: [{ Effect: "Allow", Action: "s3:GetObject", Resource: "arn:aws:s3:::bucket/*" }]
        }
      })
      expect(attrs3.has_wildcard_permissions?).to eq(false)
    end
    
    it "checks if policy allows specific actions" do
      policy = {
        Version: "2012-10-17",
        Statement: [
          { Effect: "Allow", Action: "s3:GetObject", Resource: "*" },
          { Effect: "Allow", Action: ["iam:GetRole", "iam:ListRoles"], Resource: "*" },
          { Effect: "Allow", Action: "ec2:*", Resource: "*" },
          { Effect: "Deny", Action: "s3:DeleteObject", Resource: "*" }
        ]
      }
      
      attrs = Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "test-policy",
        policy: policy
      })
      
      expect(attrs.allows_action?("s3:GetObject")).to eq(true)
      expect(attrs.allows_action?("iam:GetRole")).to eq(true)
      expect(attrs.allows_action?("iam:ListRoles")).to eq(true)
      expect(attrs.allows_action?("ec2:RunInstances")).to eq(true)  # Matches ec2:*
      expect(attrs.allows_action?("s3:PutObject")).to eq(false)
      expect(attrs.allows_action?("sts:AssumeRole")).to eq(false)
    end
    
    it "determines security risk level" do
      # High risk - wildcard permissions
      attrs1 = Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "high-risk",
        policy: {
          Version: "2012-10-17",
          Statement: [{ Effect: "Allow", Action: "*", Resource: "*" }]
        }
      })
      expect(attrs1.security_level).to eq(:high_risk)
      
      # Medium risk - IAM permissions
      attrs2 = Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "medium-risk",
        policy: {
          Version: "2012-10-17",
          Statement: [{ Effect: "Allow", Action: "iam:*", Resource: "*" }]
        }
      })
      expect(attrs2.security_level).to eq(:medium_risk)
      
      # Low risk - specific permissions
      attrs3 = Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "low-risk",
        policy: {
          Version: "2012-10-17",
          Statement: [{ Effect: "Allow", Action: "s3:GetObject", Resource: "arn:aws:s3:::bucket/*" }]
        }
      })
      expect(attrs3.security_level).to eq(:low_risk)
    end
    
    it "calculates policy complexity score" do
      simple_policy = {
        Version: "2012-10-17",
        Statement: [{
          Effect: "Allow",
          Action: "s3:GetObject",
          Resource: "arn:aws:s3:::bucket/*"
        }]
      }
      
      complex_policy = {
        Version: "2012-10-17",
        Statement: [
          {
            Effect: "Allow",
            Action: ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
            Resource: ["arn:aws:s3:::bucket1/*", "arn:aws:s3:::bucket2/*"],
            Condition: {
              IpAddress: { "aws:SourceIp": "10.0.0.0/8" }
            }
          },
          {
            Effect: "Allow",
            Action: ["iam:GetRole", "iam:ListRoles"],
            Resource: "*"
          }
        ]
      }
      
      simple_attrs = Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "simple",
        policy: simple_policy
      })
      
      complex_attrs = Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "complex",
        policy: complex_policy
      })
      
      expect(simple_attrs.complexity_score).to be < complex_attrs.complexity_score
      expect(simple_attrs.complexity_score).to eq(3)  # 1 statement + 1 action + 1 resource
      expect(complex_attrs.complexity_score).to eq(11) # 2 statements + 5 actions + 2 resources + (1 condition * 2)
    end
    
    it "detects service role policies" do
      service_role_policy = {
        Version: "2012-10-17",
        Statement: [{
          Effect: "Allow",
          Action: "sts:AssumeRole",
          Resource: "arn:aws:iam::123456789012:role/MyRole"
        }]
      }
      
      regular_policy = {
        Version: "2012-10-17",
        Statement: [{
          Effect: "Allow",
          Action: "s3:GetObject",
          Resource: "*"
        }]
      }
      
      service_attrs = Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "service-role",
        policy: service_role_policy
      })
      
      regular_attrs = Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "regular",
        policy: regular_policy
      })
      
      expect(service_attrs.service_role_policy?).to eq(true)
      expect(regular_attrs.service_role_policy?).to eq(false)
    end
  end
  
  describe "aws_iam_policy function behavior" do
    it "creates a policy with minimal attributes" do
      ref = test_instance.aws_iam_policy(:test_policy, {
        name: "TestPolicy",
        policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Action: "s3:GetObject",
            Resource: "*"
          }]
        }
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_iam_policy')
      expect(ref.name).to eq(:test_policy)
    end
    
    it "creates a policy with custom path and description" do
      ref = test_instance.aws_iam_policy(:custom_policy, {
        name: "CustomPolicy",
        path: "/service/",
        description: "Policy for service access",
        policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Action: ["s3:GetObject", "s3:PutObject"],
            Resource: "arn:aws:s3:::my-bucket/*"
          }]
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("CustomPolicy")
      expect(attrs[:path]).to eq("/service/")
      expect(attrs[:description]).to eq("Policy for service access")
    end
    
    it "creates a policy with tags" do
      ref = test_instance.aws_iam_policy(:tagged_policy, {
        name: "TaggedPolicy",
        policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Action: "s3:*",
            Resource: "*"
          }]
        },
        tags: {
          Environment: "production",
          Team: "platform"
        }
      })
      
      expect(ref.resource_attributes[:tags]).to eq({
        Environment: "production",
        Team: "platform"
      })
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_iam_policy(:test_policy, {
        name: "test-policy",
        policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Action: "s3:GetObject",
            Resource: "*"
          }]
        }
      })
      
      expected_outputs = [:id, :arn, :name, :path, :policy, :policy_id, :tags_all]
      
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_iam_policy.test_policy.")
      end
    end
    
    it "provides computed properties" do
      ref = test_instance.aws_iam_policy(:complex_policy, {
        name: "ComplexPolicy",
        policy: {
          Version: "2012-10-17",
          Statement: [
            {
              Effect: "Allow",
              Action: "*",
              Resource: "*"
            },
            {
              Effect: "Allow",
              Action: ["iam:GetRole", "iam:ListRoles"],
              Resource: "arn:aws:iam::*:role/*"
            }
          ]
        }
      })
      
      expect(ref.all_actions).to contain_exactly("*", "iam:GetRole", "iam:ListRoles")
      expect(ref.all_resources).to contain_exactly("*", "arn:aws:iam::*:role/*")
      expect(ref.security_level).to eq(:high_risk)
      expect(ref.has_wildcard_permissions?).to eq(true)
      expect(ref.uses_reserved_name?).to eq(false)
      expect(ref.service_role_policy?).to eq(false)
      expect(ref.complexity_score).to be > 0
      expect(ref.allows_action?("s3:GetObject")).to eq(true)  # Matches *
      expect(ref.allows_action?("iam:GetRole")).to eq(true)
    end
  end
  
  describe "PolicyTemplates module usage" do
    it "creates S3 read-only policy" do
      template = Pangea::Resources::AWS::PolicyTemplates.s3_bucket_readonly("my-bucket")
      ref = test_instance.aws_iam_policy(:s3_readonly, {
        name: "S3ReadOnlyPolicy",
        policy: template
      })
      
      expect(ref.all_actions).to contain_exactly("s3:GetObject", "s3:GetObjectVersion", "s3:ListBucket")
      expect(ref.all_resources).to contain_exactly("arn:aws:s3:::my-bucket/*", "arn:aws:s3:::my-bucket")
      expect(ref.security_level).to eq(:low_risk)
    end
    
    it "creates S3 full access policy" do
      template = Pangea::Resources::AWS::PolicyTemplates.s3_bucket_fullaccess("my-bucket")
      ref = test_instance.aws_iam_policy(:s3_full, {
        name: "S3FullAccessPolicy",
        policy: template
      })
      
      expect(ref.all_actions).to eq(["s3:*"])
      expect(ref.all_resources).to contain_exactly("arn:aws:s3:::my-bucket", "arn:aws:s3:::my-bucket/*")
    end
    
    it "creates CloudWatch logs write policy" do
      template = Pangea::Resources::AWS::PolicyTemplates.cloudwatch_logs_write
      ref = test_instance.aws_iam_policy(:logs_write, {
        name: "LogsWritePolicy",
        policy: template
      })
      
      expect(ref.all_actions).to contain_exactly(
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      )
    end
    
    it "creates Lambda basic execution policy" do
      template = Pangea::Resources::AWS::PolicyTemplates.lambda_basic_execution
      ref = test_instance.aws_iam_policy(:lambda_exec, {
        name: "LambdaExecutionPolicy",
        policy: template
      })
      
      expect(ref.all_actions).to contain_exactly(
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      )
      expect(ref.all_resources).to eq(["arn:aws:logs:*:*:*"])
    end
    
    it "creates KMS decrypt policy" do
      template = Pangea::Resources::AWS::PolicyTemplates.kms_decrypt("arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012")
      ref = test_instance.aws_iam_policy(:kms_decrypt, {
        name: "KMSDecryptPolicy",
        policy: template
      })
      
      expect(ref.all_actions).to contain_exactly("kms:Decrypt", "kms:DescribeKey")
      expect(ref.all_resources).to eq(["arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"])
    end
    
    it "creates SSM parameter read policy" do
      template = Pangea::Resources::AWS::PolicyTemplates.ssm_parameter_read("/myapp/")
      ref = test_instance.aws_iam_policy(:ssm_read, {
        name: "SSMReadPolicy",
        policy: template
      })
      
      expect(ref.all_actions).to contain_exactly(
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      )
      expect(ref.all_resources).to eq(["arn:aws:ssm:*:*:parameter/myapp/*"])
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_iam_policy(:test_policy, {
        name: "test-policy",
        policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Action: "s3:GetObject",
            Resource: "*"
          }]
        }
      })
      
      expect(ref.outputs[:id]).to eq("${aws_iam_policy.test_policy.id}")
      expect(ref.outputs[:arn]).to eq("${aws_iam_policy.test_policy.arn}")
      expect(ref.outputs[:name]).to eq("${aws_iam_policy.test_policy.name}")
      expect(ref.outputs[:policy_id]).to eq("${aws_iam_policy.test_policy.policy_id}")
    end
    
    it "can be used with other AWS resources" do
      policy_ref = test_instance.aws_iam_policy(:app_policy, {
        name: "application-policy",
        policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Action: ["s3:GetObject", "s3:PutObject"],
            Resource: "arn:aws:s3:::app-bucket/*"
          }]
        }
      })
      
      # Simulate using policy reference for role attachment
      policy_arn = policy_ref.outputs[:arn]
      
      expect(policy_arn).to eq("${aws_iam_policy.app_policy.arn}")
    end
  end
  
  describe "error conditions and edge cases" do
    it "handles string keys in attributes" do
      ref = test_instance.aws_iam_policy(:string_keys, {
        "name" => "string-key-policy",
        "path" => "/test/",
        "policy" => {
          "Version" => "2012-10-17",
          "Statement" => [{
            "Effect" => "Allow",
            "Action" => "s3:*",
            "Resource" => "*"
          }]
        }
      })
      
      expect(ref.resource_attributes[:name]).to eq("string-key-policy")
      expect(ref.resource_attributes[:path]).to eq("/test/")
    end
    
    it "handles complex policy conditions" do
      complex_policy = {
        Version: "2012-10-17",
        Statement: [{
          Effect: "Allow",
          Action: "s3:GetObject",
          Resource: "arn:aws:s3:::my-bucket/*",
          Condition: {
            IpAddress: { "aws:SourceIp": ["10.0.0.0/8", "172.16.0.0/12"] },
            DateGreaterThan: { "aws:CurrentTime": "2024-01-01T00:00:00Z" },
            StringEquals: { "s3:x-amz-server-side-encryption": "AES256" }
          }
        }]
      }
      
      ref = test_instance.aws_iam_policy(:conditional, {
        name: "ConditionalPolicy",
        policy: complex_policy
      })
      
      expect(ref.complexity_score).to eq(5)  # 1 statement + 1 action + 1 resource + (1 condition * 2)
    end
    
    it "handles NotAction and NotResource" do
      policy = {
        Version: "2012-10-17",
        Statement: [{
          Effect: "Allow",
          NotAction: ["iam:*", "sts:*"],
          NotResource: "arn:aws:iam::*:*"
        }]
      }
      
      ref = test_instance.aws_iam_policy(:not_policy, {
        name: "NotActionPolicy",
        policy: policy
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      # NotAction and NotResource don't contribute to all_actions/all_resources
      expect(ref.all_actions).to be_empty
      expect(ref.all_resources).to be_empty
    end
  end
  
  describe "security validation" do
    # Suppress security warnings during tests
    before do
      allow($stdout).to receive(:puts)
    end
    
    it "warns about wildcard permissions" do
      expect($stdout).to receive(:puts).with(/wildcard .* permissions/)
      
      Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "wildcard-policy",
        policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Action: "*",
            Resource: "*"
          }]
        }
      })
    end
    
    it "warns about dangerous IAM actions" do
      expect($stdout).to receive(:puts).with(/potentially dangerous action: iam:\*/)
      
      Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "dangerous-policy",
        policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Action: "iam:*",
            Resource: "*"
          }]
        }
      })
    end
    
    it "warns about root resource access" do
      expect($stdout).to receive(:puts).with(/grants access to root resources/)
      
      Pangea::Resources::AWS::IamPolicyAttributes.new({
        name: "root-access-policy",
        policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Action: "sts:AssumeRole",
            Resource: "arn:aws:iam::123456789012:root"
          }]
        }
      })
    end
  end
end