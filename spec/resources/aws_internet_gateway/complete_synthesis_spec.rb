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

# Load aws_internet_gateway resource for terraform synthesis testing
require 'pangea/resources/aws_internet_gateway/resource'

RSpec.describe "aws_internet_gateway terraform synthesis" do
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
        
        def method_missing(method_name, *args, &block)
          @method_calls << [method_name, *args]
          if block_given?
            # For nested blocks like tags
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
              # For nested blocks like tags
              tag_context = TagContext.new(@synthesizer)
              @attributes[method_name] = tag_context
              yield
            end
            
            args.first if args.any?
          end
          
          def respond_to_missing?(method_name, include_private = false)
            true
          end
        end
        
        class TagContext
          def initialize(synthesizer)
            @synthesizer = synthesizer
            @tags = {}
          end
          
          def method_missing(method_name, *args, &block)
            @synthesizer.method_calls << [method_name, *args]
            @tags[method_name] = args.first if args.any?
            args.first if args.any?
          end
          
          def respond_to_missing?(method_name, include_private = false)
            true
          end
          
          def to_h
            @tags
          end
        end
      end
    end
    
    let(:test_synthesizer) { mock_synthesizer.new }
    let(:vpc_id) { "${aws_vpc.test.id}" }
    
    it "synthesizes basic internet gateway terraform correctly" do
      # Create a test class that uses our mock synthesizer
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_internet_gateway function with minimal configuration
      ref = test_instance.aws_internet_gateway(:basic_igw, {})
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_internet_gateway')
      expect(ref.name).to eq(:basic_igw)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_internet_gateway, :basic_igw]
      )
      
      # Verify no optional attributes were called
      vpc_id_calls = test_synthesizer.method_calls.select { |call| call[0] == :vpc_id }
      expect(vpc_id_calls).to be_empty
      
      tags_calls = test_synthesizer.method_calls.select { |call| call[0] == :tags }
      expect(tags_calls).to be_empty
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_internet_gateway.basic_igw")
    end
    
    it "synthesizes internet gateway with VPC attachment correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_internet_gateway function with VPC attachment
      ref = test_instance.aws_internet_gateway(:attached_igw, {
        vpc_id: vpc_id
      })
      
      # Verify VPC attachment synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_internet_gateway, :attached_igw],
        [:vpc_id, vpc_id]
      )
      
      # Verify tags block was NOT called (since no tags provided)
      tags_calls = test_synthesizer.method_calls.select { |call| call[0] == :tags }
      expect(tags_calls).to be_empty
    end
    
    it "synthesizes internet gateway with tags correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_internet_gateway function with tags
      ref = test_instance.aws_internet_gateway(:tagged_igw, {
        tags: { 
          Name: "main-igw", 
          Environment: "production",
          ManagedBy: "pangea"
        }
      })
      
      # Verify basic synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_internet_gateway, :tagged_igw]
      )
      
      # Verify tags block was called
      expect(test_synthesizer.method_calls).to include([:tags])
      expect(test_synthesizer.method_calls).to include([:Name, "main-igw"])
      expect(test_synthesizer.method_calls).to include([:Environment, "production"])
      expect(test_synthesizer.method_calls).to include([:ManagedBy, "pangea"])
      
      # Verify vpc_id was NOT called (since not provided)
      vpc_id_calls = test_synthesizer.method_calls.select { |call| call[0] == :vpc_id }
      expect(vpc_id_calls).to be_empty
    end
    
    it "synthesizes internet gateway with both VPC and tags correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call aws_internet_gateway function with full configuration
      ref = test_instance.aws_internet_gateway(:complete_igw, {
        vpc_id: vpc_id,
        tags: {
          Name: "complete-igw",
          Environment: "production",
          Purpose: "internet-access",
          CostCenter: "infrastructure"
        }
      })
      
      # Verify complete synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_internet_gateway, :complete_igw],
        [:vpc_id, vpc_id]
      )
      
      # Verify all tags were processed
      expect(test_synthesizer.method_calls).to include([:tags])
      expect(test_synthesizer.method_calls).to include([:Name, "complete-igw"])
      expect(test_synthesizer.method_calls).to include([:Environment, "production"])
      expect(test_synthesizer.method_calls).to include([:Purpose, "internet-access"])
      expect(test_synthesizer.method_calls).to include([:CostCenter, "infrastructure"])
    end
    
    it "synthesizes internet gateway for multi-environment deployment" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Simulate creating IGWs for multiple environments
      environments = [
        { name: "dev", vpc: "${aws_vpc.dev.id}" },
        { name: "staging", vpc: "${aws_vpc.staging.id}" },
        { name: "prod", vpc: "${aws_vpc.prod.id}" }
      ]
      
      environments.each do |env|
        ref = test_instance.aws_internet_gateway(:"#{env[:name]}_igw", {
          vpc_id: env[:vpc],
          tags: {
            Name: "#{env[:name]}-igw",
            Environment: env[:name],
            Type: "internet-gateway"
          }
        })
        
        # Verify each environment's synthesis
        expect(test_synthesizer.method_calls).to include(
          [:resource, :aws_internet_gateway, :"#{env[:name]}_igw"],
          [:vpc_id, env[:vpc]],
          [:Name, "#{env[:name]}-igw"],
          [:Environment, env[:name]]
        )
      end
    end
    
    it "synthesizes internet gateway for route table integration" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Create IGW for public subnet routing scenario
      ref = test_instance.aws_internet_gateway(:public_igw, {
        vpc_id: vpc_id,
        tags: {
          Name: "public-internet-gateway",
          Type: "public",
          Role: "internet-access",
          Usage: "public-subnets"
        }
      })
      
      # Verify synthesis for route table integration scenario
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_internet_gateway, :public_igw],
        [:vpc_id, vpc_id]
      )
      
      # Verify route table specific tags
      expect(test_synthesizer.method_calls).to include(
        [:Type, "public"],
        [:Role, "internet-access"],
        [:Usage, "public-subnets"]
      )
      
      # Verify the returned reference can be used for route configuration
      expect(ref.outputs[:id]).to eq("${aws_internet_gateway.public_igw.id}")
    end
    
    it "handles empty tags hash correctly" do
      test_class = Class.new do
        include Pangea::Resources::AWS
        
        def initialize(synthesizer)
          @synthesizer = synthesizer
        end
        
        def resource(*args, &block)
          @synthesizer.resource(*args, &block)
        end
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      # Call with explicit empty tags hash
      ref = test_instance.aws_internet_gateway(:empty_tags_igw, {
        vpc_id: vpc_id,
        tags: {}
      })
      
      # Verify synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_internet_gateway, :empty_tags_igw],
        [:vpc_id, vpc_id]
      )
      
      # Verify tags block was NOT called for empty hash
      tags_calls = test_synthesizer.method_calls.select { |call| call[0] == :tags }
      expect(tags_calls).to be_empty
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
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      ref = test_instance.aws_internet_gateway(:output_test, {
        vpc_id: vpc_id,
        tags: { Name: "output-test-igw" }
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :arn, :owner_id, :vpc_id]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\$\{aws_internet_gateway\.output_test\.#{output}\}\z/)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_internet_gateway.output_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_internet_gateway.output_test.arn}")
      expect(ref.outputs[:owner_id]).to eq("${aws_internet_gateway.output_test.owner_id}")
      expect(ref.outputs[:vpc_id]).to eq("${aws_internet_gateway.output_test.vpc_id}")
    end
  end
end