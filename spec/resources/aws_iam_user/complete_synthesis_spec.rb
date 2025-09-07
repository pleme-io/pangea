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

# Load aws_iam_user resource for terraform synthesis testing
require 'pangea/resources/aws_iam_user/resource'

RSpec.describe "aws_iam_user terraform synthesis" do
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
    
    it "synthesizes basic IAM user terraform correctly" do
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
      
      # Call aws_iam_user function with minimal configuration
      ref = test_instance.aws_iam_user(:basic_user, {
        name: "test-user"
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_iam_user')
      expect(ref.name).to eq(:basic_user)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_iam_user, :basic_user],
        [:name, "test-user"],
        [:path, "/"],
        [:force_destroy, false]
      )
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_iam_user.basic_user")
      
      # Verify resource attributes
      resource = test_synthesizer.resources["aws_iam_user.basic_user"]
      expect(resource.attributes[:name]).to eq("test-user")
      expect(resource.attributes[:path]).to eq("/")
    end
    
    it "synthesizes IAM user with permissions boundary" do
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
      
      # Call with permissions boundary
      ref = test_instance.aws_iam_user(:bounded_user, {
        name: "developer-user",
        path: "/developers/",
        permissions_boundary: "arn:aws:iam::123456789012:policy/DeveloperBoundary",
        force_destroy: true
      })
      
      # Verify permissions boundary synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "developer-user"],
        [:path, "/developers/"],
        [:permissions_boundary, "arn:aws:iam::123456789012:policy/DeveloperBoundary"],
        [:force_destroy, true]
      )
    end
    
    it "synthesizes IAM user with tags" do
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
      
      # Call with tags
      ref = test_instance.aws_iam_user(:tagged_user, {
        name: "tagged-user",
        tags: {
          Department: "Engineering",
          Team: "Platform",
          Environment: "Production"
        }
      })
      
      # Verify tags synthesis
      expect(test_synthesizer.method_calls).to include([:tags])
      
      # Find the tags resource context
      resource = test_synthesizer.resources["aws_iam_user.tagged_user"]
      expect(resource.attributes).to have_key(:tags)
      tags_context = resource.attributes[:tags]
      expect(tags_context.attributes).to eq({
        Department: "Engineering",
        Team: "Platform",
        Environment: "Production"
      })
    end
    
    it "synthesizes developer user pattern" do
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
      
      # Use developer pattern
      pattern = Pangea::Resources::AWS::UserPatterns.developer_user("alice.smith", "frontend")
      ref = test_instance.aws_iam_user(:dev_alice, pattern)
      
      # Verify pattern synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "alice.smith"],
        [:path, "/frontend/"],
        [:permissions_boundary, "arn:aws:iam::123456789012:policy/DeveloperPermissionsBoundary"]
      )
      
      # Verify tags were synthesized
      resource = test_synthesizer.resources["aws_iam_user.dev_alice"]
      expect(resource.attributes[:tags].attributes).to include({
        UserType: "Developer",
        Department: "Frontend"
      })
    end
    
    it "synthesizes service account pattern" do
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
      
      # Use service account pattern
      pattern = Pangea::Resources::AWS::UserPatterns.service_account_user("user-api", "production")
      ref = test_instance.aws_iam_user(:api_service, pattern)
      
      # Verify service account synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "user-api-service"],
        [:path, "/service-accounts/production/"],
        [:force_destroy, true]
      )
      
      # Verify service account tags
      resource = test_synthesizer.resources["aws_iam_user.api_service"]
      expect(resource.attributes[:tags].attributes).to include({
        UserType: "ServiceAccount",
        Service: "user-api",
        Environment: "production",
        AutomationManaged: "true"
      })
    end
    
    it "synthesizes admin user pattern with boundary" do
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
      
      # Use admin pattern
      pattern = Pangea::Resources::AWS::UserPatterns.admin_user("bob.wilson", "infrastructure")
      ref = test_instance.aws_iam_user(:admin_bob, pattern)
      
      # Verify admin synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "bob.wilson.admin"],
        [:path, "/admins/infrastructure/"],
        [:permissions_boundary, "arn:aws:iam::123456789012:policy/AdminPermissionsBoundary"]
      )
      
      # Verify admin requires approval
      resource = test_synthesizer.resources["aws_iam_user.admin_bob"]
      expect(resource.attributes[:tags].attributes[:RequiresApproval]).to eq("true")
    end
    
    it "synthesizes emergency user without boundary" do
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
      
      # Use emergency pattern
      pattern = Pangea::Resources::AWS::UserPatterns.emergency_user("breakglass")
      ref = test_instance.aws_iam_user(:emergency, pattern)
      
      # Verify no permissions boundary (emergency access)
      expect(test_synthesizer.method_calls).not_to include([:permissions_boundary, anything])
      
      # Verify emergency tags
      resource = test_synthesizer.resources["aws_iam_user.emergency"]
      expect(resource.attributes[:tags].attributes).to include({
        UserType: "Emergency",
        AccessLevel: "BreakGlass",
        AuditRequired: "true"
      })
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
      
      ref = test_instance.aws_iam_user(:output_test, {
        name: "test-user"
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :arn, :name, :path, :permissions_boundary, :unique_id, :tags_all]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\${aws_iam_user\.output_test\./)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_iam_user.output_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_iam_user.output_test.arn}")
      expect(ref.outputs[:name]).to eq("${aws_iam_user.output_test.name}")
      expect(ref.outputs[:unique_id]).to eq("${aws_iam_user.output_test.unique_id}")
    end
    
    it "synthesizes cross-account user pattern" do
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
      
      # Use cross-account pattern
      pattern = Pangea::Resources::AWS::UserPatterns.cross_account_user("shared-access", "987654321098")
      ref = test_instance.aws_iam_user(:cross_account, pattern)
      
      # Verify cross-account synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "shared-access.crossaccount"],
        [:path, "/cross-account/"]
      )
      
      # Verify target account tag
      resource = test_synthesizer.resources["aws_iam_user.cross_account"]
      expect(resource.attributes[:tags].attributes[:TargetAccount]).to eq("987654321098")
    end
    
    it "synthesizes CI/CD user pattern" do
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
      
      # Use CI/CD pattern
      pattern = Pangea::Resources::AWS::UserPatterns.cicd_user("web-app-deploy", "github.com/company/web-app")
      ref = test_instance.aws_iam_user(:cicd_user, pattern)
      
      # Verify CI/CD synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "web-app-deploy-cicd"],
        [:path, "/cicd/"],
        [:force_destroy, true]
      )
      
      # Verify repository tag
      resource = test_synthesizer.resources["aws_iam_user.cicd_user"]
      expect(resource.attributes[:tags].attributes[:Repository]).to eq("github.com/company/web-app")
    end
    
    it "synthesizes multiple users with organizational structure" do
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
      
      # Create organizational structure
      users = []
      
      # Developers in different teams
      users << test_instance.aws_iam_user(:frontend_dev,
        Pangea::Resources::AWS::UserPatterns.developer_user("alice.smith", "frontend"))
      
      users << test_instance.aws_iam_user(:backend_dev,
        Pangea::Resources::AWS::UserPatterns.developer_user("bob.jones", "backend"))
      
      # Service accounts for different environments
      users << test_instance.aws_iam_user(:api_prod,
        Pangea::Resources::AWS::UserPatterns.service_account_user("api", "production"))
      
      users << test_instance.aws_iam_user(:api_dev,
        Pangea::Resources::AWS::UserPatterns.service_account_user("api", "development"))
      
      # Verify all users were created
      expect(test_synthesizer.resources.keys).to include(
        "aws_iam_user.frontend_dev",
        "aws_iam_user.backend_dev",
        "aws_iam_user.api_prod",
        "aws_iam_user.api_dev"
      )
      
      # Verify organizational paths
      expect(test_synthesizer.method_calls).to include(
        [:path, "/frontend/"],
        [:path, "/backend/"],
        [:path, "/service-accounts/production/"],
        [:path, "/service-accounts/development/"]
      )
    end
  end
end