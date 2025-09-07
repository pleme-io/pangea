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

# Load aws_security_group resource for terraform synthesis testing
require 'pangea/resources/aws_security_group/resource'

RSpec.describe "aws_security_group terraform synthesis" do
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
    
    it "synthesizes basic security group terraform correctly" do
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
      
      # Call aws_security_group function
      ref = test_instance.aws_security_group(:test_sg, {
        name_prefix: "web-sg-",
        vpc_id: vpc_id,
        description: "Test security group"
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_security_group')
      expect(ref.name).to eq(:test_sg)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_security_group, :test_sg],
        [:name_prefix, "web-sg-"],
        [:vpc_id, vpc_id],
        [:description, "Test security group"]
      )
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_security_group.test_sg")
    end
    
    it "synthesizes security group with ingress rules correctly" do
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
      
      ingress_rules = [
        {
          from_port: 80,
          to_port: 80,
          protocol: "tcp",
          cidr_blocks: ["0.0.0.0/0"]
        },
        {
          from_port: 443,
          to_port: 443,
          protocol: "tcp",
          cidr_blocks: ["0.0.0.0/0"]
        }
      ]
      
      # Call aws_security_group function with ingress rules
      ref = test_instance.aws_security_group(:web_sg, {
        name_prefix: "web-",
        vpc_id: vpc_id,
        description: "Web server security group",
        ingress_rules: ingress_rules
      })
      
      # Verify basic terraform synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_security_group, :web_sg],
        [:name_prefix, "web-"],
        [:vpc_id, vpc_id],
        [:description, "Web server security group"]
      )
      
      # Verify ingress rules were processed
      expect(test_synthesizer.method_calls).to include(
        [:ingress, ingress_rules.map { |rule| rule.merge(security_groups: []) }]
      )
    end
    
    it "synthesizes security group with egress rules correctly" do
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
      
      egress_rules = [
        {
          from_port: 0,
          to_port: 65535,
          protocol: "-1",
          cidr_blocks: ["0.0.0.0/0"]
        }
      ]
      
      # Call aws_security_group function with egress rules
      ref = test_instance.aws_security_group(:outbound_sg, {
        name_prefix: "outbound-",
        vpc_id: vpc_id,
        description: "Outbound security group",
        egress_rules: egress_rules
      })
      
      # Verify terraform synthesis for egress rules
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_security_group, :outbound_sg],
        [:name_prefix, "outbound-"],
        [:vpc_id, vpc_id],
        [:description, "Outbound security group"]
      )
      
      # Verify egress rules were processed
      expect(test_synthesizer.method_calls).to include(
        [:egress, egress_rules.map { |rule| rule.merge(security_groups: []) }]
      )
    end
    
    it "synthesizes security group with tags correctly" do
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
      
      # Call aws_security_group function with tags
      ref = test_instance.aws_security_group(:tagged_sg, {
        name_prefix: "tagged-sg-",
        vpc_id: vpc_id,
        description: "Tagged security group",
        tags: { Name: "test-sg", Environment: "production" }
      })
      
      # Verify basic terraform synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_security_group, :tagged_sg],
        [:name_prefix, "tagged-sg-"],
        [:vpc_id, vpc_id],
        [:description, "Tagged security group"]
      )
      
      # Verify tags block was called
      expect(test_synthesizer.method_calls).to include([:tags])
      expect(test_synthesizer.method_calls).to include([:Name, "test-sg"])
      expect(test_synthesizer.method_calls).to include([:Environment, "production"])
    end
    
    it "handles security group without optional attributes correctly" do
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
      
      # Call aws_security_group function with minimal attributes
      ref = test_instance.aws_security_group(:minimal_sg, {})
      
      # Verify basic synthesis without optional attributes
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_security_group, :minimal_sg]
      )
      
      # Verify optional attributes were NOT called
      name_prefix_calls = test_synthesizer.method_calls.select { |call| call[0] == :name_prefix }
      expect(name_prefix_calls).to be_empty
      
      vpc_id_calls = test_synthesizer.method_calls.select { |call| call[0] == :vpc_id }
      expect(vpc_id_calls).to be_empty
      
      description_calls = test_synthesizer.method_calls.select { |call| call[0] == :description }
      expect(description_calls).to be_empty
      
      # Verify tags block was NOT called (since no tags provided)
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
      
      ref = test_instance.aws_security_group(:output_test, {
        name_prefix: "test-",
        vpc_id: vpc_id,
        description: "Test security group"
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :arn, :vpc_id, :owner_id, :name]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\$\{aws_security_group\.output_test\.#{output}\}\z/)
      end
    end
  end
end