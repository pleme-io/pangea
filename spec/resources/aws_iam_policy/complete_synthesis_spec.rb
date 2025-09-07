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

# Load aws_iam_policy resource for terraform synthesis testing
require 'pangea/resources/aws_iam_policy/resource'

RSpec.describe "aws_iam_policy terraform synthesis" do
  describe "real terraform synthesis" do
    # Note: These tests require terraform_synthesizer gem to be available
    # They test actual terraform JSON generation
    
    let(:mock_synthesizer) do
      # Mock synthesizer that captures method calls to verify terraform structure
      Class.new do
        attr_reader :resources, :method_calls
        
        def initialize
          @resources = {}
          @method_calls = []
        end
        
        def resource(type, name)
          @method_calls << [:resource, type, name]
          resource_context = ResourceContext.new(self, type, name)
          @resources["#{type}.#{name}"] = resource_context
          yield resource_context if block_given?
          resource_context
        end
        
        def ref(type, name, attribute)
          "${#{type}.#{name}.#{attribute}}"
        end
        
        def method_missing(method_name, *args, &block)
          @method_calls << [method_name, *args]
          if block_given?
            # For nested blocks like tags
            nested_context = NestedContext.new(self, method_name)
            yield nested_context
          end
          args.first if args.any?
        end
        
        def respond_to_missing?(method_name, include_private = false)
          true
        end
        
        class ResourceContext
          attr_reader :synthesizer, :type, :name, :attributes
          
          def initialize(synthesizer, type, name)
            @synthesizer = synthesizer
            @type = type
            @name = name
            @attributes = {}
          end
          
          def method_missing(method_name, *args, &block)
            @synthesizer.method_calls << [method_name, *args]
            @attributes[method_name] = args.first if args.any?
            
            if block_given?
              # For nested blocks
              nested_context = NestedContext.new(@synthesizer, method_name)
              @attributes[method_name] = nested_context
              yield nested_context
            end
            
            args.first if args.any?
          end
          
          def respond_to_missing?(method_name, include_private = false)
            true
          end
        end
        
        class NestedContext
          attr_reader :synthesizer, :context_name, :attributes
          
          def initialize(synthesizer, context_name)
            @synthesizer = synthesizer
            @context_name = context_name
            @attributes = {}
          end
          
          def method_missing(method_name, *args, &block)
            @synthesizer.method_calls << [method_name, *args]
            @attributes[method_name] = args.first if args.any?
            
            if block_given?
              # For deeply nested blocks
              nested = NestedContext.new(@synthesizer, method_name)
              @attributes[method_name] = nested
              yield nested
            end
            
            args.first if args.any?
          end
          
          def respond_to_missing?(method_name, include_private = false)
            true
          end
        end
      end
    end
    
    let(:test_synthesizer) { mock_synthesizer.new }
    
    it "synthesizes basic IAM policy terraform correctly" do
      # Create a test class that uses our mock synthesizer
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_iam_policy function with minimal configuration
      ref = test_instance.aws_iam_policy(:basic_policy, {
        name: "BasicPolicy",
        policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Action: "s3:GetObject",
            Resource: "arn:aws:s3:::my-bucket/*"
          }]
        }
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_iam_policy')
      expect(ref.name).to eq(:basic_policy)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_iam_policy, :basic_policy],
        [:name, "BasicPolicy"],
        [:path, "/"]
      )
      
      # Verify policy JSON was called
      policy_call = test_synthesizer.method_calls.find { |call| call[0] == :policy }
      expect(policy_call).not_to be_nil
      expect(policy_call[1]).to be_a(String)
      expect(JSON.parse(policy_call[1])).to eq({
        "Version" => "2012-10-17",
        "Statement" => [{
          "Effect" => "Allow",
          "Action" => "s3:GetObject",
          "Resource" => "arn:aws:s3:::my-bucket/*"
        }]
      })
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_iam_policy.basic_policy")
    end
    
    it "synthesizes IAM policy with custom path and description" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_iam_policy function with custom attributes
      ref = test_instance.aws_iam_policy(:custom_policy, {
        name: "CustomPolicy",
        path: "/service/",
        description: "Service-specific IAM policy",
        policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Action: ["s3:GetObject", "s3:PutObject"],
            Resource: "arn:aws:s3:::service-bucket/*"
          }]
        }
      })
      
      # Verify custom attributes synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "CustomPolicy"],
        [:path, "/service/"],
        [:description, "Service-specific IAM policy"]
      )
    end
    
    it "synthesizes IAM policy with tags" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_iam_policy function with tags
      ref = test_instance.aws_iam_policy(:tagged_policy, {
        name: "TaggedPolicy",
        policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            Action: "s3:ListBucket",
            Resource: "*"
          }]
        },
        tags: {
          Environment: "production",
          Team: "platform",
          ManagedBy: "terraform"
        }
      })
      
      # Verify tags synthesis
      expect(test_synthesizer.method_calls).to include([:tags])
      
      # Find the tags resource context
      resource = test_synthesizer.resources["aws_iam_policy.tagged_policy"]
      expect(resource.attributes).to have_key(:tags)
      tags_context = resource.attributes[:tags]
      expect(tags_context.attributes).to eq({
        Environment: "production",
        Team: "platform",
        ManagedBy: "terraform"
      })
    end
    
    it "synthesizes complex multi-statement policy correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_iam_policy function with complex policy
      ref = test_instance.aws_iam_policy(:complex_policy, {
        name: "ComplexPolicy",
        policy: {
          Version: "2012-10-17",
          Statement: [
            {
              Sid: "S3Access",
              Effect: "Allow",
              Action: ["s3:GetObject", "s3:PutObject"],
              Resource: ["arn:aws:s3:::bucket1/*", "arn:aws:s3:::bucket2/*"]
            },
            {
              Sid: "EC2Describe",
              Effect: "Allow",
              Action: "ec2:Describe*",
              Resource: "*"
            },
            {
              Sid: "ConditionalAccess",
              Effect: "Allow",
              Action: "iam:GetRole",
              Resource: "arn:aws:iam::*:role/*",
              Condition: {
                StringEquals: { "aws:RequestedRegion": "us-east-1" }
              }
            }
          ]
        }
      })
      
      # Verify complex policy synthesis
      policy_call = test_synthesizer.method_calls.find { |call| call[0] == :policy }
      expect(policy_call).not_to be_nil
      
      parsed_policy = JSON.parse(policy_call[1])
      expect(parsed_policy["Statement"].length).to eq(3)
      expect(parsed_policy["Statement"][0]["Sid"]).to eq("S3Access")
      expect(parsed_policy["Statement"][2]["Condition"]).to eq({
        "StringEquals" => { "aws:RequestedRegion" => "us-east-1" }
      })
    end
    
    it "synthesizes policy template correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Use S3 bucket read-only template
      template = Pangea::Resources::AWS::PolicyTemplates.s3_bucket_readonly("my-bucket")
      ref = test_instance.aws_iam_policy(:s3_readonly, {
        name: "S3ReadOnlyPolicy",
        policy: template
      })
      
      # Verify template synthesis
      policy_call = test_synthesizer.method_calls.find { |call| call[0] == :policy }
      parsed_policy = JSON.parse(policy_call[1])
      
      expect(parsed_policy["Statement"].length).to eq(2)
      expect(parsed_policy["Statement"][0]["Action"]).to eq(["s3:GetObject", "s3:GetObjectVersion"])
      expect(parsed_policy["Statement"][0]["Resource"]).to eq("arn:aws:s3:::my-bucket/*")
      expect(parsed_policy["Statement"][1]["Action"]).to eq(["s3:ListBucket"])
      expect(parsed_policy["Statement"][1]["Resource"]).to eq("arn:aws:s3:::my-bucket")
    end
    
    it "synthesizes CloudWatch logs template correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Use CloudWatch logs write template
      template = Pangea::Resources::AWS::PolicyTemplates.cloudwatch_logs_write
      ref = test_instance.aws_iam_policy(:logs_write, {
        name: "LogsWritePolicy",
        policy: template
      })
      
      # Verify template synthesis
      policy_call = test_synthesizer.method_calls.find { |call| call[0] == :policy }
      parsed_policy = JSON.parse(policy_call[1])
      
      expect(parsed_policy["Statement"][0]["Action"]).to include("logs:CreateLogGroup", "logs:PutLogEvents")
    end
    
    it "validates terraform reference outputs" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      ref = test_instance.aws_iam_policy(:output_test, {
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
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :arn, :name, :path, :policy, :policy_id, :tags_all]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\${aws_iam_policy\.output_test\./)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_iam_policy.output_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_iam_policy.output_test.arn}")
      expect(ref.outputs[:name]).to eq("${aws_iam_policy.output_test.name}")
      expect(ref.outputs[:policy_id]).to eq("${aws_iam_policy.output_test.policy_id}")
    end
    
    it "handles policy with NotAction and NotResource" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      ref = test_instance.aws_iam_policy(:not_policy, {
        name: "NotActionPolicy",
        policy: {
          Version: "2012-10-17",
          Statement: [{
            Effect: "Allow",
            NotAction: ["iam:*", "sts:*"],
            NotResource: "arn:aws:iam::*:*"
          }]
        }
      })
      
      # Verify NotAction/NotResource synthesis
      policy_call = test_synthesizer.method_calls.find { |call| call[0] == :policy }
      parsed_policy = JSON.parse(policy_call[1])
      
      expect(parsed_policy["Statement"][0]["NotAction"]).to eq(["iam:*", "sts:*"])
      expect(parsed_policy["Statement"][0]["NotResource"]).to eq("arn:aws:iam::*:*")
    end
    
    it "synthesizes KMS decrypt template with specific key" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Use KMS decrypt template
      key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      template = Pangea::Resources::AWS::PolicyTemplates.kms_decrypt(key_arn)
      ref = test_instance.aws_iam_policy(:kms_decrypt, {
        name: "KMSDecryptPolicy",
        policy: template
      })
      
      # Verify template synthesis with parameter substitution
      policy_call = test_synthesizer.method_calls.find { |call| call[0] == :policy }
      parsed_policy = JSON.parse(policy_call[1])
      
      expect(parsed_policy["Statement"][0]["Action"]).to eq(["kms:Decrypt", "kms:DescribeKey"])
      expect(parsed_policy["Statement"][0]["Resource"]).to eq(key_arn)
    end
    
    it "synthesizes Lambda execution role policy" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def ref(*args)
          @synthesizer.ref(*args)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Use Lambda basic execution template
      template = Pangea::Resources::AWS::PolicyTemplates.lambda_basic_execution
      ref = test_instance.aws_iam_policy(:lambda_exec, {
        name: "LambdaExecutionPolicy",
        description: "Basic execution policy for Lambda functions",
        policy: template
      })
      
      # Verify Lambda policy synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "LambdaExecutionPolicy"],
        [:description, "Basic execution policy for Lambda functions"]
      )
      
      policy_call = test_synthesizer.method_calls.find { |call| call[0] == :policy }
      parsed_policy = JSON.parse(policy_call[1])
      
      expect(parsed_policy["Statement"][0]["Action"]).to include(
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      )
      expect(parsed_policy["Statement"][0]["Resource"]).to eq("arn:aws:logs:*:*:*")
    end
  end
end