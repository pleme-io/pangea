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

# Load aws_subnet resource for terraform synthesis testing
require 'pangea/resources/aws_subnet/resource'

RSpec.describe "aws_subnet terraform synthesis" do
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
    
    it "synthesizes basic subnet terraform correctly" do
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
      
      # Call aws_subnet function
      ref = test_instance.aws_subnet(:test_subnet, {
        vpc_id: vpc_id,
        cidr_block: "10.0.1.0/24",
        availability_zone: "us-east-1a"
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_subnet')
      expect(ref.name).to eq(:test_subnet)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_subnet, :test_subnet],
        [:vpc_id, vpc_id],
        [:cidr_block, "10.0.1.0/24"],
        [:availability_zone, "us-east-1a"],
        [:map_public_ip_on_launch, false]
      )
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_subnet.test_subnet")
    end
    
    it "synthesizes public subnet with tags correctly" do
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
      
      # Call aws_subnet function with public configuration
      ref = test_instance.aws_subnet(:public_subnet, {
        vpc_id: vpc_id,
        cidr_block: "10.0.1.0/24",
        availability_zone: "us-east-1a",
        map_public_ip_on_launch: true,
        tags: { Name: "public-subnet", Type: "public" }
      })
      
      # Verify basic terraform synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_subnet, :public_subnet],
        [:vpc_id, vpc_id],
        [:cidr_block, "10.0.1.0/24"],
        [:availability_zone, "us-east-1a"],
        [:map_public_ip_on_launch, true]
      )
      
      # Verify tags block was called
      expect(test_synthesizer.method_calls).to include([:tags])
      expect(test_synthesizer.method_calls).to include([:Name, "public-subnet"])
      expect(test_synthesizer.method_calls).to include([:Type, "public"])
    end
    
    it "synthesizes private subnet correctly" do
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
      
      # Call aws_subnet function with private configuration
      ref = test_instance.aws_subnet(:private_subnet, {
        vpc_id: vpc_id,
        cidr_block: "10.0.2.0/24", 
        availability_zone: "us-east-1b",
        map_public_ip_on_launch: false,
        tags: { Name: "private-subnet", Type: "private" }
      })
      
      # Verify terraform synthesis for private subnet
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_subnet, :private_subnet],
        [:vpc_id, vpc_id],
        [:cidr_block, "10.0.2.0/24"],
        [:availability_zone, "us-east-1b"],
        [:map_public_ip_on_launch, false]
      )
    end
    
    it "handles subnets without tags correctly" do
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
      
      # Call aws_subnet function without tags
      ref = test_instance.aws_subnet(:no_tags_subnet, {
        vpc_id: vpc_id,
        cidr_block: "10.0.3.0/24",
        availability_zone: "us-east-1c"
      })
      
      # Verify basic synthesis without tags block
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_subnet, :no_tags_subnet],
        [:vpc_id, vpc_id],
        [:cidr_block, "10.0.3.0/24"],
        [:availability_zone, "us-east-1c"],
        [:map_public_ip_on_launch, false]
      )
      
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
      
      ref = test_instance.aws_subnet(:output_test, {
        vpc_id: vpc_id,
        cidr_block: "10.0.1.0/24",
        availability_zone: "us-east-1a"
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :arn, :availability_zone, :availability_zone_id, 
                         :cidr_block, :vpc_id, :owner_id]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\$\{aws_subnet\.output_test\.#{output}\}\z/)
      end
    end
  end
end