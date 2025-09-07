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

# Load aws_iam_role resource for terraform synthesis testing
require 'pangea/resources/aws_iam_role/resource'

RSpec.describe "aws_iam_role terraform synthesis" do
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
          yield if block_given?
          resource_context
        end
        
        def ref(type, name, attribute)
          "${#{type}.#{name}.#{attribute}}"
        end
        
        def method_missing(method_name, *args, &block)
          @method_calls << [method_name, *args]
          if block_given?
            # For nested blocks like inline_policy, tags, etc.
            nested_context = NestedContext.new(self, method_name)
            yield
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
              yield
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
              yield
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
    
    it "synthesizes basic IAM role terraform correctly" do
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
      
      # Call aws_iam_role function with minimal configuration
      ref = test_instance.aws_iam_role(:basic_role, {
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_iam_role')
      expect(ref.name).to eq(:basic_role)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_iam_role, :basic_role],
        [:path, "/"],
        [:force_detach_policies, false],
        [:max_session_duration, 3600]
      )
      
      # Verify assume_role_policy was called with JSON
      assume_role_policy_calls = test_synthesizer.method_calls.select { |call| call[0] == :assume_role_policy }
      expect(assume_role_policy_calls).not_to be_empty
      expect(assume_role_policy_calls.first[1]).to include('2012-10-17')
      expect(assume_role_policy_calls.first[1]).to include('ec2.amazonaws.com')
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_iam_role.basic_role")
    end
    
    it "synthesizes role with custom name correctly" do
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
      
      # Call aws_iam_role function with custom name
      ref = test_instance.aws_iam_role(:named_role, {
        name: "MyCustomRoleName",
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.lambda_service
      })
      
      # Verify name synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "MyCustomRoleName"]
      )
      
      # Verify Lambda trust policy
      assume_role_policy_calls = test_synthesizer.method_calls.select { |call| call[0] == :assume_role_policy }
      expect(assume_role_policy_calls.first[1]).to include('lambda.amazonaws.com')
    end
    
    it "synthesizes role with name prefix correctly" do
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
      
      # Call aws_iam_role function with name prefix
      ref = test_instance.aws_iam_role(:prefixed_role, {
        name_prefix: "app-role-",
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ecs_task_service
      })
      
      # Verify name_prefix synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name_prefix, "app-role-"]
      )
      
      # Verify name was NOT called
      name_calls = test_synthesizer.method_calls.select { |call| call[0] == :name }
      expect(name_calls).to be_empty
    end
    
    it "synthesizes role with description and path correctly" do
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
      
      # Call aws_iam_role function with description and path
      ref = test_instance.aws_iam_role(:described_role, {
        path: "/application/backend/",
        description: "Backend service role for data processing",
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service
      })
      
      # Verify description and path synthesis
      expect(test_synthesizer.method_calls).to include(
        [:path, "/application/backend/"],
        [:description, "Backend service role for data processing"]
      )
    end
    
    it "synthesizes inline policies correctly" do
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
      
      # Call aws_iam_role function with inline policies
      ref = test_instance.aws_iam_role(:inline_policy_role, {
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.lambda_service,
        inline_policies: {
          "CloudWatchLogs" => {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
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
      
      # Verify inline_policy blocks were created
      inline_policy_calls = test_synthesizer.method_calls.count { |call| call[0] == :inline_policy }
      expect(inline_policy_calls).to eq(2)
      
      # Verify policy names
      expect(test_synthesizer.method_calls).to include(
        [:name, "CloudWatchLogs"],
        [:name, "S3Access"]
      )
      
      # Verify policy content includes JSON
      policy_calls = test_synthesizer.method_calls.select { |call| call[0] == :policy }
      expect(policy_calls.size).to eq(2)
      expect(policy_calls[0][1]).to include('logs:CreateLogGroup')
      expect(policy_calls[1][1]).to include('s3:GetObject')
    end
    
    it "synthesizes cross-account trust policy with conditions correctly" do
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
      
      # Call aws_iam_role function with cross-account trust policy
      ref = test_instance.aws_iam_role(:cross_account_role, {
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
        max_session_duration: 7200
      })
      
      # Verify trust policy includes conditions
      assume_role_policy_calls = test_synthesizer.method_calls.select { |call| call[0] == :assume_role_policy }
      policy_json = assume_role_policy_calls.first[1]
      expect(policy_json).to include('arn:aws:iam::987654321098:root')
      expect(policy_json).to include('unique-external-id')
      
      # Verify max session duration
      expect(test_synthesizer.method_calls).to include(
        [:max_session_duration, 7200]
      )
    end
    
    it "synthesizes permissions boundary correctly" do
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
      
      # Call aws_iam_role function with permissions boundary
      ref = test_instance.aws_iam_role(:bounded_role, {
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service,
        permissions_boundary: "arn:aws:iam::123456789012:policy/DeveloperBoundary"
      })
      
      # Verify permissions boundary synthesis
      expect(test_synthesizer.method_calls).to include(
        [:permissions_boundary, "arn:aws:iam::123456789012:policy/DeveloperBoundary"]
      )
    end
    
    it "synthesizes tags correctly" do
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
      
      # Call aws_iam_role function with tags
      ref = test_instance.aws_iam_role(:tagged_role, {
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.lambda_service,
        tags: {
          Name: "LambdaExecutionRole",
          Environment: "production",
          Application: "data-processor",
          ManagedBy: "terraform"
        }
      })
      
      # Verify tags synthesis
      expect(test_synthesizer.method_calls).to include(
        [:tags],
        [:Name, "LambdaExecutionRole"],
        [:Environment, "production"],
        [:Application, "data-processor"],
        [:ManagedBy, "terraform"]
      )
    end
    
    it "synthesizes SAML federated role correctly" do
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
      
      # Call aws_iam_role function with SAML trust policy
      ref = test_instance.aws_iam_role(:saml_role, {
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.saml_federated(
          "arn:aws:iam::123456789012:saml-provider/CompanySAML"
        ),
        max_session_duration: 28800  # 8 hours
      })
      
      # Verify SAML trust policy synthesis
      assume_role_policy_calls = test_synthesizer.method_calls.select { |call| call[0] == :assume_role_policy }
      policy_json = assume_role_policy_calls.first[1]
      expect(policy_json).to include('arn:aws:iam::123456789012:saml-provider/CompanySAML')
      expect(policy_json).to include('sts:AssumeRoleWithSAML')
      expect(policy_json).to include('https://signin.aws.amazon.com/saml')
    end
    
    it "synthesizes comprehensive role configuration correctly" do
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
      
      # Call aws_iam_role function with comprehensive config
      ref = test_instance.aws_iam_role(:comprehensive_role, {
        name: "ComprehensiveRole",
        path: "/application/",
        description: "A comprehensive IAM role example",
        assume_role_policy: {
          Version: "2012-10-17",
          Statement: [
            {
              Effect: "Allow",
              Principal: { Service: ["ec2.amazonaws.com", "ecs.amazonaws.com"] },
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
        },
        force_detach_policies: true,
        max_session_duration: 14400,
        permissions_boundary: "arn:aws:iam::123456789012:policy/AppBoundary",
        inline_policies: {
          "AppPolicy" => {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: ["s3:ListBucket", "s3:GetObject"],
              Resource: ["arn:aws:s3:::app-bucket", "arn:aws:s3:::app-bucket/*"]
            }]
          }
        },
        tags: {
          Name: "ComprehensiveRole",
          Type: "multi-service"
        }
      })
      
      # Verify comprehensive synthesis includes all major components
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_iam_role, :comprehensive_role],
        [:name, "ComprehensiveRole"],
        [:path, "/application/"],
        [:description, "A comprehensive IAM role example"],
        [:force_detach_policies, true],
        [:max_session_duration, 14400],
        [:permissions_boundary, "arn:aws:iam::123456789012:policy/AppBoundary"]
      )
      
      # Verify inline policy was created
      expect(test_synthesizer.method_calls).to include([:inline_policy])
      
      # Verify tags were created
      expect(test_synthesizer.method_calls).to include([:tags])
    end
    
    it "handles conditional attributes correctly" do
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
      
      # Call with minimal config (no optional attributes)
      ref = test_instance.aws_iam_role(:minimal, {
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.ec2_service
      })
      
      # Verify optional attributes were not synthesized
      name_calls = test_synthesizer.method_calls.select { |call| call[0] == :name }
      name_prefix_calls = test_synthesizer.method_calls.select { |call| call[0] == :name_prefix }
      description_calls = test_synthesizer.method_calls.select { |call| call[0] == :description }
      permissions_boundary_calls = test_synthesizer.method_calls.select { |call| call[0] == :permissions_boundary }
      
      expect(name_calls).to be_empty
      expect(name_prefix_calls).to be_empty
      expect(description_calls).to be_empty
      expect(permissions_boundary_calls).to be_empty
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
      
      ref = test_instance.aws_iam_role(:output_test, {
        assume_role_policy: Pangea::Resources::AWS::TrustPolicies.lambda_service
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :arn, :name, :unique_id, :create_date]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\$\{aws_iam_role\.output_test\./)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_iam_role.output_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_iam_role.output_test.arn}")
      expect(ref.outputs[:name]).to eq("${aws_iam_role.output_test.name}")
    end
  end
end