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

# Load aws_iam_group resource for terraform synthesis testing
require 'pangea/resources/aws_iam_group/resource'

RSpec.describe "aws_iam_group terraform synthesis" do
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
            # For nested blocks like tags
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
    
    it "synthesizes basic IAM group terraform correctly" do
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
      
      # Call aws_iam_group function with minimal configuration
      ref = test_instance.aws_iam_group(:basic_group, {
        name: "developers"
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_iam_group')
      expect(ref.name).to eq(:basic_group)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_iam_group, :basic_group],
        [:name, "developers"],
        [:path, "/"]
      )
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_iam_group.basic_group")
    end
    
    it "synthesizes IAM group with custom path correctly" do
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
      
      # Call aws_iam_group function with custom path
      ref = test_instance.aws_iam_group(:team_group, {
        name: "engineering-developers",
        path: "/teams/engineering/"
      })
      
      # Verify path synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "engineering-developers"],
        [:path, "/teams/engineering/"]
      )
    end
    
    it "synthesizes development team group pattern correctly" do
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
      
      # Use GroupPatterns helper
      pattern = Pangea::Resources::AWS::GroupPatterns.development_team_group("frontend", "engineering")
      ref = test_instance.aws_iam_group(:frontend_devs, pattern)
      
      # Verify pattern synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "engineering-frontend-developers"],
        [:path, "/teams/engineering/frontend/"]
      )
    end
    
    it "synthesizes administrative group correctly" do
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
      
      # Use GroupPatterns for admin group
      pattern = Pangea::Resources::AWS::GroupPatterns.admin_group("infrastructure", "platform")
      ref = test_instance.aws_iam_group(:infra_admins, pattern)
      
      # Verify admin group synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "platform-infrastructure-admins"],
        [:path, "/admins/platform/"]
      )
    end
    
    it "synthesizes environment access group correctly" do
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
      
      # Use GroupPatterns for environment group
      pattern = Pangea::Resources::AWS::GroupPatterns.environment_access_group("production", "deploy")
      ref = test_instance.aws_iam_group(:prod_deploy, pattern)
      
      # Verify environment group synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "production-deploy"],
        [:path, "/environments/production/"]
      )
    end
    
    it "synthesizes service group correctly" do
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
      
      # Use GroupPatterns for service group
      pattern = Pangea::Resources::AWS::GroupPatterns.service_group("user-api", "operator")
      ref = test_instance.aws_iam_group(:api_operators, pattern)
      
      # Verify service group synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "user-api-operator"],
        [:path, "/services/user-api/"]
      )
    end
    
    it "synthesizes readonly group correctly" do
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
      
      # Use GroupPatterns for readonly group
      pattern = Pangea::Resources::AWS::GroupPatterns.readonly_group("infrastructure", "monitoring")
      ref = test_instance.aws_iam_group(:infra_readonly, pattern)
      
      # Verify readonly group synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "infrastructure-readonly-monitoring"],
        [:path, "/readonly/"]
      )
    end
    
    it "synthesizes emergency access group correctly" do
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
      
      # Use GroupPatterns for emergency group
      pattern = Pangea::Resources::AWS::GroupPatterns.emergency_group("breakglass")
      ref = test_instance.aws_iam_group(:emergency, pattern)
      
      # Verify emergency group synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "emergency-breakglass"],
        [:path, "/emergency/"]
      )
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
      
      ref = test_instance.aws_iam_group(:output_test, {
        name: "test-group"
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :arn, :name, :path, :unique_id]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\${aws_iam_group\.output_test\./)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_iam_group.output_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_iam_group.output_test.arn}")
      expect(ref.outputs[:name]).to eq("${aws_iam_group.output_test.name}")
      expect(ref.outputs[:unique_id]).to eq("${aws_iam_group.output_test.unique_id}")
    end
    
    it "synthesizes complex organizational structure correctly" do
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
      
      # Create multiple groups with organizational structure
      groups = []
      
      # Department groups
      groups << test_instance.aws_iam_group(:eng_standard, 
        Pangea::Resources::AWS::GroupPatterns.department_group("engineering", "standard"))
      
      groups << test_instance.aws_iam_group(:finance_elevated,
        Pangea::Resources::AWS::GroupPatterns.department_group("finance", "elevated"))
      
      # Environment groups
      groups << test_instance.aws_iam_group(:prod_deploy,
        Pangea::Resources::AWS::GroupPatterns.environment_access_group("production", "deploy"))
      
      # Cross-functional groups
      groups << test_instance.aws_iam_group(:data_platform,
        Pangea::Resources::AWS::GroupPatterns.cross_functional_group("data-platform", ["engineering", "analytics"]))
      
      # Verify all groups were synthesized
      expect(test_synthesizer.resources.keys).to include(
        "aws_iam_group.eng_standard",
        "aws_iam_group.finance_elevated",
        "aws_iam_group.prod_deploy",
        "aws_iam_group.data_platform"
      )
      
      # Verify organizational paths
      expect(test_synthesizer.method_calls).to include(
        [:path, "/departments/engineering/"],
        [:path, "/departments/finance/"],
        [:path, "/environments/production/"],
        [:path, "/cross-functional/engineering-analytics/"]
      )
    end
  end
end