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

# Load aws_iam_role_policy_attachment resource for terraform synthesis testing
require 'pangea/resources/aws_iam_role_policy_attachment/resource'

RSpec.describe "aws_iam_role_policy_attachment terraform synthesis" do
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
    
    it "synthesizes basic role policy attachment terraform correctly" do
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
      
      # Call aws_iam_role_policy_attachment function with minimal configuration
      ref = test_instance.aws_iam_role_policy_attachment(:basic_attachment, {
        role: "test-role",
        policy_arn: "arn:aws:iam::aws:policy/ReadOnlyAccess"
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_iam_role_policy_attachment')
      expect(ref.name).to eq(:basic_attachment)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_iam_role_policy_attachment, :basic_attachment],
        [:role, "test-role"],
        [:policy_arn, "arn:aws:iam::aws:policy/ReadOnlyAccess"]
      )
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_iam_role_policy_attachment.basic_attachment")
      
      # Verify resource attributes
      resource = test_synthesizer.resources["aws_iam_role_policy_attachment.basic_attachment"]
      expect(resource.attributes[:role]).to eq("test-role")
      expect(resource.attributes[:policy_arn]).to eq("arn:aws:iam::aws:policy/ReadOnlyAccess")
    end
    
    it "synthesizes attachment with role ARN correctly" do
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
      
      # Call with role ARN instead of name
      ref = test_instance.aws_iam_role_policy_attachment(:arn_attachment, {
        role: "arn:aws:iam::123456789012:role/cross-account-role",
        policy_arn: "arn:aws:iam::aws:policy/AdministratorAccess"
      })
      
      # Verify ARN synthesis
      expect(test_synthesizer.method_calls).to include(
        [:role, "arn:aws:iam::123456789012:role/cross-account-role"],
        [:policy_arn, "arn:aws:iam::aws:policy/AdministratorAccess"]
      )
    end
    
    it "synthesizes Lambda execution role attachment pattern" do
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
      
      # Use AWS managed policy constant
      ref = test_instance.aws_iam_role_policy_attachment(:lambda_exec, {
        role: "lambda-execution-role",
        policy_arn: Pangea::Resources::AWS::AwsManagedPolicies::Lambda::BASIC_EXECUTION_ROLE
      })
      
      # Verify correct policy ARN synthesis
      expect(test_synthesizer.method_calls).to include(
        [:role, "lambda-execution-role"],
        [:policy_arn, "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
      )
    end
    
    it "synthesizes multiple attachments for same role" do
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
      
      # Create multiple attachments for the same role
      role_name = "multi-policy-role"
      
      ref1 = test_instance.aws_iam_role_policy_attachment(:multi_1, {
        role: role_name,
        policy_arn: Pangea::Resources::AWS::AwsManagedPolicies::S3::READ_ONLY
      })
      
      ref2 = test_instance.aws_iam_role_policy_attachment(:multi_2, {
        role: role_name,
        policy_arn: Pangea::Resources::AWS::AwsManagedPolicies::CloudWatch::READ_ONLY
      })
      
      ref3 = test_instance.aws_iam_role_policy_attachment(:multi_3, {
        role: role_name,
        policy_arn: "arn:aws:iam::123456789012:policy/custom-policy"
      })
      
      # Verify all attachments were created
      expect(test_synthesizer.resources).to have_key("aws_iam_role_policy_attachment.multi_1")
      expect(test_synthesizer.resources).to have_key("aws_iam_role_policy_attachment.multi_2")
      expect(test_synthesizer.resources).to have_key("aws_iam_role_policy_attachment.multi_3")
      
      # Verify all attachments reference the same role
      expect(test_synthesizer.resources["aws_iam_role_policy_attachment.multi_1"].attributes[:role]).to eq(role_name)
      expect(test_synthesizer.resources["aws_iam_role_policy_attachment.multi_2"].attributes[:role]).to eq(role_name)
      expect(test_synthesizer.resources["aws_iam_role_policy_attachment.multi_3"].attributes[:role]).to eq(role_name)
    end
    
    it "synthesizes attachment pattern collections" do
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
      
      # Use attachment pattern for Lambda VPC execution
      policies = Pangea::Resources::AWS::AttachmentPatterns.lambda_vpc_execution_role_policies
      
      policies.each_with_index do |policy_arn, index|
        test_instance.aws_iam_role_policy_attachment(:"lambda_vpc_#{index}", {
          role: "lambda-vpc-role",
          policy_arn: policy_arn
        })
      end
      
      # Verify both policies were attached
      expect(test_synthesizer.resources).to have_key("aws_iam_role_policy_attachment.lambda_vpc_0")
      expect(test_synthesizer.resources).to have_key("aws_iam_role_policy_attachment.lambda_vpc_1")
      
      # Verify correct policy ARNs
      expect(test_synthesizer.resources["aws_iam_role_policy_attachment.lambda_vpc_0"].attributes[:policy_arn])
        .to eq("arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole")
      
      expect(test_synthesizer.resources["aws_iam_role_policy_attachment.lambda_vpc_1"].attributes[:policy_arn])
        .to eq("arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole")
    end
    
    it "synthesizes ECS task execution pattern" do
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
      
      # Use ECS task execution pattern
      policies = Pangea::Resources::AWS::AttachmentPatterns.ecs_task_execution_policies
      
      policies.each_with_index do |policy_arn, index|
        test_instance.aws_iam_role_policy_attachment(:"ecs_task_#{index}", {
          role: "ecs-task-execution-role",
          policy_arn: policy_arn
        })
      end
      
      # Verify ECS task execution policy attachment
      expect(test_synthesizer.resources["aws_iam_role_policy_attachment.ecs_task_0"].attributes[:policy_arn])
        .to eq("arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy")
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
      
      ref = test_instance.aws_iam_role_policy_attachment(:output_test, {
        role: "test-role",
        policy_arn: "arn:aws:iam::aws:policy/ReadOnlyAccess"
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :role, :policy_arn]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\${aws_iam_role_policy_attachment\.output_test\./)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_iam_role_policy_attachment.output_test.id}")
      expect(ref.outputs[:role]).to eq("${aws_iam_role_policy_attachment.output_test.role}")
      expect(ref.outputs[:policy_arn]).to eq("${aws_iam_role_policy_attachment.output_test.policy_arn}")
    end
    
    it "synthesizes cross-account policy attachment" do
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
      
      # Cross-account attachment
      ref = test_instance.aws_iam_role_policy_attachment(:cross_account, {
        role: "arn:aws:iam::111111111111:role/cross-account-role",
        policy_arn: "arn:aws:iam::222222222222:policy/shared-policy"
      })
      
      # Verify cross-account synthesis
      resource = test_synthesizer.resources["aws_iam_role_policy_attachment.cross_account"]
      expect(resource.attributes[:role]).to eq("arn:aws:iam::111111111111:role/cross-account-role")
      expect(resource.attributes[:policy_arn]).to eq("arn:aws:iam::222222222222:policy/shared-policy")
    end
    
    it "synthesizes environment-specific policy patterns" do
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
      
      # Development environment (more permissive)
      dev_policies = Pangea::Resources::AWS::AttachmentPatterns.development_policies
      dev_policies.each_with_index do |policy_arn, index|
        test_instance.aws_iam_role_policy_attachment(:"dev_policy_#{index}", {
          role: "dev-role",
          policy_arn: policy_arn
        })
      end
      
      # Verify development policies
      expect(test_synthesizer.resources["aws_iam_role_policy_attachment.dev_policy_0"].attributes[:policy_arn])
        .to eq("arn:aws:iam::aws:policy/AmazonS3FullAccess")
      
      # Production environment (restrictive)
      prod_policies = Pangea::Resources::AWS::AttachmentPatterns.production_read_only_policies
      prod_policies.each_with_index do |policy_arn, index|
        test_instance.aws_iam_role_policy_attachment(:"prod_policy_#{index}", {
          role: "prod-readonly-role",
          policy_arn: policy_arn
        })
      end
      
      # Verify production policies
      expect(test_synthesizer.resources["aws_iam_role_policy_attachment.prod_policy_0"].attributes[:policy_arn])
        .to eq("arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess")
    end
    
    it "synthesizes administrative policy attachments with proper identification" do
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
      
      # Attach administrative policies
      admin_policies = Pangea::Resources::AWS::AwsManagedPolicies.administrative_policies
      
      # Should contain dangerous policies
      expect(admin_policies).to include("arn:aws:iam::aws:policy/AdministratorAccess")
      
      ref = test_instance.aws_iam_role_policy_attachment(:admin_attachment, {
        role: "admin-role",
        policy_arn: admin_policies.first
      })
      
      # Verify synthesis
      expect(test_synthesizer.method_calls).to include(
        [:role, "admin-role"],
        [:policy_arn, "arn:aws:iam::aws:policy/AdministratorAccess"]
      )
      
      # Verify dangerous policy detection
      expect(ref.potentially_dangerous?).to eq(true)
      expect(ref.security_risk_level).to eq(:high)
    end
  end
end