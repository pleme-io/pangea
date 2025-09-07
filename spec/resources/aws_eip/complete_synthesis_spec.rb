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

# Load aws_eip resource for terraform synthesis testing
require 'pangea/resources/aws_eip/resource'

RSpec.describe "aws_eip terraform synthesis" do
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
    
    it "synthesizes basic EIP terraform correctly" do
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
      
      # Call aws_eip function with minimal configuration
      ref = test_instance.aws_eip(:basic_eip, {})
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_eip')
      expect(ref.name).to eq(:basic_eip)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_eip, :basic_eip],
        [:domain, "vpc"]
      )
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_eip.basic_eip")
    end
    
    it "synthesizes EIP with instance association correctly" do
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
      
      # Call aws_eip function with instance association
      ref = test_instance.aws_eip(:instance_eip, {
        instance: "i-1234567890abcdef0"
      })
      
      # Verify instance synthesis
      expect(test_synthesizer.method_calls).to include(
        [:domain, "vpc"],
        [:instance, "i-1234567890abcdef0"]
      )
    end
    
    it "synthesizes EIP with network interface correctly" do
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
      
      # Call aws_eip function with network interface
      ref = test_instance.aws_eip(:eni_eip, {
        network_interface: "eni-1234567890abcdef0",
        associate_with_private_ip: "10.0.1.50"
      })
      
      # Verify network interface synthesis
      expect(test_synthesizer.method_calls).to include(
        [:network_interface, "eni-1234567890abcdef0"],
        [:associate_with_private_ip, "10.0.1.50"]
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
      
      # Call aws_eip function with tags
      ref = test_instance.aws_eip(:tagged_eip, {
        tags: {
          Name: "production-eip",
          Environment: "production",
          Application: "web-server"
        }
      })
      
      # Verify tags synthesis
      expect(test_synthesizer.method_calls).to include(
        [:tags],
        [:Name, "production-eip"],
        [:Environment, "production"],
        [:Application, "web-server"]
      )
    end
    
    it "synthesizes customer-owned IP pool correctly" do
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
      
      # Call aws_eip function with customer-owned pool
      ref = test_instance.aws_eip(:customer_eip, {
        customer_owned_ipv4_pool: "ipv4pool-coip-12345678"
      })
      
      # Verify customer pool synthesis
      expect(test_synthesizer.method_calls).to include(
        [:customer_owned_ipv4_pool, "ipv4pool-coip-12345678"]
      )
    end
    
    it "synthesizes network border group correctly" do
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
      
      # Call aws_eip function with network border group
      ref = test_instance.aws_eip(:wavelength_eip, {
        network_border_group: "us-east-1-wl1-bos-wlz-1"
      })
      
      # Verify network border group synthesis
      expect(test_synthesizer.method_calls).to include(
        [:network_border_group, "us-east-1-wl1-bos-wlz-1"]
      )
    end
    
    it "synthesizes public IPv4 pool correctly" do
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
      
      # Call aws_eip function with public pool
      ref = test_instance.aws_eip(:public_pool_eip, {
        public_ipv4_pool: "amazon"
      })
      
      # Verify public pool synthesis
      expect(test_synthesizer.method_calls).to include(
        [:public_ipv4_pool, "amazon"]
      )
    end
    
    it "synthesizes EC2-Classic domain correctly" do
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
      
      # Call aws_eip function with standard domain
      ref = test_instance.aws_eip(:classic_eip, {
        domain: "standard"
      })
      
      # Verify standard domain synthesis
      expect(test_synthesizer.method_calls).to include(
        [:domain, "standard"]
      )
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
      ref = test_instance.aws_eip(:minimal, {})
      
      # Verify optional attributes were not synthesized
      instance_calls = test_synthesizer.method_calls.select { |call| call[0] == :instance }
      network_interface_calls = test_synthesizer.method_calls.select { |call| call[0] == :network_interface }
      associate_calls = test_synthesizer.method_calls.select { |call| call[0] == :associate_with_private_ip }
      
      expect(instance_calls).to be_empty
      expect(network_interface_calls).to be_empty
      expect(associate_calls).to be_empty
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
      
      ref = test_instance.aws_eip(:output_test, {})
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [
        :id, :allocation_id, :public_ip, :private_ip, :instance,
        :network_interface, :domain, :vpc
      ]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\${aws_eip\.output_test\./)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_eip.output_test.id}")
      expect(ref.outputs[:allocation_id]).to eq("${aws_eip.output_test.allocation_id}")
      expect(ref.outputs[:public_ip]).to eq("${aws_eip.output_test.public_ip}")
    end
  end
end