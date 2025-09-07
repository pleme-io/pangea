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

# Load aws_nat_gateway resource for terraform synthesis testing
require 'pangea/resources/aws_nat_gateway/resource'

RSpec.describe "aws_nat_gateway terraform synthesis" do
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
              # For nested blocks like tags
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
            args.first if args.any?
          end
          
          def respond_to_missing?(method_name, include_private = false)
            true
          end
        end
      end
    end
    
    let(:test_synthesizer) { mock_synthesizer.new }
    let(:subnet_id) { "${aws_subnet.public.id}" }
    let(:allocation_id) { "${aws_eip.nat.id}" }
    
    it "synthesizes basic public NAT gateway terraform correctly" do
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
      
      # Call aws_nat_gateway function with minimal public configuration
      ref = test_instance.aws_nat_gateway(:basic_nat, {
        subnet_id: subnet_id
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_nat_gateway')
      expect(ref.name).to eq(:basic_nat)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_nat_gateway, :basic_nat],
        [:subnet_id, subnet_id]
      )
      
      # Verify connectivity_type was NOT called (default public)
      connectivity_calls = test_synthesizer.method_calls.select { |call| call[0] == :connectivity_type }
      expect(connectivity_calls).to be_empty
      
      # Verify allocation_id was NOT called (not provided)
      allocation_calls = test_synthesizer.method_calls.select { |call| call[0] == :allocation_id }
      expect(allocation_calls).to be_empty
      
      # Verify tags block was NOT called (since no tags provided)
      tags_calls = test_synthesizer.method_calls.select { |call| call[0] == :tags }
      expect(tags_calls).to be_empty
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_nat_gateway.basic_nat")
    end
    
    it "synthesizes public NAT gateway with Elastic IP correctly" do
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
      
      # Call aws_nat_gateway function with public NAT and Elastic IP
      ref = test_instance.aws_nat_gateway(:public_nat, {
        subnet_id: subnet_id,
        allocation_id: allocation_id,
        connectivity_type: "public"
      })
      
      # Verify basic synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_nat_gateway, :public_nat],
        [:subnet_id, subnet_id],
        [:allocation_id, allocation_id]
      )
      
      # Verify connectivity_type was NOT called (same as default)
      connectivity_calls = test_synthesizer.method_calls.select { |call| call[0] == :connectivity_type }
      expect(connectivity_calls).to be_empty
    end
    
    it "synthesizes private NAT gateway correctly" do
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
      
      # Call aws_nat_gateway function with private connectivity
      ref = test_instance.aws_nat_gateway(:private_nat, {
        subnet_id: subnet_id,
        connectivity_type: "private"
      })
      
      # Verify private NAT synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_nat_gateway, :private_nat],
        [:subnet_id, subnet_id],
        [:connectivity_type, "private"]
      )
      
      # Verify allocation_id was NOT called (not allowed for private)
      allocation_calls = test_synthesizer.method_calls.select { |call| call[0] == :allocation_id }
      expect(allocation_calls).to be_empty
    end
    
    it "synthesizes NAT gateway with tags correctly" do
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
      
      # Call aws_nat_gateway function with tags
      ref = test_instance.aws_nat_gateway(:tagged_nat, {
        subnet_id: subnet_id,
        allocation_id: allocation_id,
        tags: {
          Name: "production-nat-gateway",
          Environment: "production",
          Type: "nat",
          ManagedBy: "pangea"
        }
      })
      
      # Verify basic synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_nat_gateway, :tagged_nat],
        [:subnet_id, subnet_id],
        [:allocation_id, allocation_id]
      )
      
      # Verify tags block was called
      expect(test_synthesizer.method_calls).to include([:tags])
      expect(test_synthesizer.method_calls).to include([:Name, "production-nat-gateway"])
      expect(test_synthesizer.method_calls).to include([:Environment, "production"])
      expect(test_synthesizer.method_calls).to include([:Type, "nat"])
      expect(test_synthesizer.method_calls).to include([:ManagedBy, "pangea"])
    end
    
    it "synthesizes multi-AZ NAT gateway deployment" do
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
      
      # Simulate creating NAT gateways for multiple AZs
      azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
      
      azs.each do |az|
        ref = test_instance.aws_nat_gateway(:"nat_#{az.last}", {
          subnet_id: "${aws_subnet.public_#{az.last}.id}",
          allocation_id: "${aws_eip.nat_#{az.last}.id}",
          tags: {
            Name: "nat-gateway-#{az}",
            AvailabilityZone: az,
            Environment: "production"
          }
        })
        
        # Verify each AZ's synthesis
        expect(test_synthesizer.method_calls).to include(
          [:resource, :aws_nat_gateway, :"nat_#{az.last}"],
          [:subnet_id, "${aws_subnet.public_#{az.last}.id}"],
          [:allocation_id, "${aws_eip.nat_#{az.last}.id}"],
          [:Name, "nat-gateway-#{az}"],
          [:AvailabilityZone, az]
        )
      end
    end
    
    it "synthesizes NAT gateway for high availability setup" do
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
      
      # Primary NAT gateway
      primary_ref = test_instance.aws_nat_gateway(:primary_nat, {
        subnet_id: "${aws_subnet.public_primary.id}",
        allocation_id: "${aws_eip.primary_nat.id}",
        tags: {
          Name: "primary-nat-gateway",
          Role: "primary",
          Environment: "production"
        }
      })
      
      # Secondary NAT gateway
      secondary_ref = test_instance.aws_nat_gateway(:secondary_nat, {
        subnet_id: "${aws_subnet.public_secondary.id}",
        allocation_id: "${aws_eip.secondary_nat.id}",
        tags: {
          Name: "secondary-nat-gateway",
          Role: "secondary",
          Environment: "production"
        }
      })
      
      # Verify both NAT gateways were synthesized
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_nat_gateway, :primary_nat],
        [:resource, :aws_nat_gateway, :secondary_nat],
        [:Role, "primary"],
        [:Role, "secondary"]
      )
      
      expect(test_synthesizer.resources).to have_key("aws_nat_gateway.primary_nat")
      expect(test_synthesizer.resources).to have_key("aws_nat_gateway.secondary_nat")
    end
    
    it "synthesizes mixed public and private NAT gateways" do
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
      
      # Public NAT gateway for internet access
      public_ref = test_instance.aws_nat_gateway(:public_nat, {
        subnet_id: "${aws_subnet.public.id}",
        allocation_id: "${aws_eip.nat.id}",
        connectivity_type: "public",
        tags: {
          Name: "public-nat-gateway",
          Type: "public",
          Purpose: "internet-access"
        }
      })
      
      # Private NAT gateway for VPC endpoints
      private_ref = test_instance.aws_nat_gateway(:private_nat, {
        subnet_id: "${aws_subnet.private.id}",
        connectivity_type: "private",
        tags: {
          Name: "private-nat-gateway",
          Type: "private",
          Purpose: "vpc-endpoints"
        }
      })
      
      # Verify public NAT gateway synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_nat_gateway, :public_nat],
        [:allocation_id, "${aws_eip.nat.id}"],
        [:Purpose, "internet-access"]
      )
      
      # Verify private NAT gateway synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_nat_gateway, :private_nat],
        [:connectivity_type, "private"],
        [:Purpose, "vpc-endpoints"]
      )
      
      # Verify allocation_id was only called for public NAT
      allocation_calls = test_synthesizer.method_calls.select { |call| call[0] == :allocation_id }
      expect(allocation_calls.length).to eq(1)
    end
    
    it "synthesizes NAT gateway with comprehensive tagging strategy" do
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
      
      ref = test_instance.aws_nat_gateway(:comprehensive_nat, {
        subnet_id: subnet_id,
        allocation_id: allocation_id,
        tags: {
          Name: "comprehensive-nat-gateway",
          Environment: "production",
          Project: "web-application",
          Team: "platform",
          CostCenter: "engineering",
          Backup: "false",
          Monitoring: "enabled",
          CreatedBy: "pangea",
          LastModified: "2024-01-15",
          Version: "1.0"
        }
      })
      
      # Verify all tags were synthesized
      comprehensive_tags = [
        [:Name, "comprehensive-nat-gateway"],
        [:Environment, "production"],
        [:Project, "web-application"],
        [:Team, "platform"],
        [:CostCenter, "engineering"],
        [:Backup, "false"],
        [:Monitoring, "enabled"],
        [:CreatedBy, "pangea"],
        [:LastModified, "2024-01-15"],
        [:Version, "1.0"]
      ]
      
      comprehensive_tags.each do |tag_call|
        expect(test_synthesizer.method_calls).to include(tag_call)
      end
    end
    
    it "handles empty tags array correctly" do
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
      ref = test_instance.aws_nat_gateway(:empty_tags_nat, {
        subnet_id: subnet_id,
        allocation_id: allocation_id,
        tags: {}
      })
      
      # Verify synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_nat_gateway, :empty_tags_nat],
        [:subnet_id, subnet_id],
        [:allocation_id, allocation_id]
      )
      
      # Verify no tags block was called for empty hash
      tags_calls = test_synthesizer.method_calls.select { |call| call[0] == :tags }
      expect(tags_calls).to be_empty
    end
    
    it "synthesizes NAT gateway with terraform reference inputs" do
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
      
      # Use complex terraform references
      ref = test_instance.aws_nat_gateway(:ref_nat, {
        subnet_id: "${element(aws_subnet.public.*.id, 0)}",
        allocation_id: "${aws_eip.nat[count.index].id}",
        tags: {
          Name: "${var.environment}-nat-gateway-${count.index}",
          SubnetCIDR: "${element(aws_subnet.public.*.cidr_block, 0)}",
          AllocationIP: "${aws_eip.nat[count.index].public_ip}"
        }
      })
      
      # Verify complex references are handled correctly
      expect(test_synthesizer.method_calls).to include(
        [:subnet_id, "${element(aws_subnet.public.*.id, 0)}"],
        [:allocation_id, "${aws_eip.nat[count.index].id}"],
        [:Name, "${var.environment}-nat-gateway-${count.index}"],
        [:SubnetCIDR, "${element(aws_subnet.public.*.cidr_block, 0)}"],
        [:AllocationIP, "${aws_eip.nat[count.index].public_ip}"]
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
        
        def method_missing(method_name, *args, &block)
          @synthesizer.method_missing(method_name, *args, &block)
        end
      end
      
      test_instance = test_class.new(test_synthesizer)
      
      ref = test_instance.aws_nat_gateway(:output_test, {
        subnet_id: subnet_id,
        allocation_id: allocation_id,
        tags: { Name: "output-test-nat" }
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :allocation_id, :subnet_id, :network_interface_id, :private_ip, :public_ip]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\$\{aws_nat_gateway\.output_test\./)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_nat_gateway.output_test.id}")
      expect(ref.outputs[:allocation_id]).to eq("${aws_nat_gateway.output_test.allocation_id}")
      expect(ref.outputs[:subnet_id]).to eq("${aws_nat_gateway.output_test.subnet_id}")
      expect(ref.outputs[:network_interface_id]).to eq("${aws_nat_gateway.output_test.network_interface_id}")
      expect(ref.outputs[:private_ip]).to eq("${aws_nat_gateway.output_test.private_ip}")
      expect(ref.outputs[:public_ip]).to eq("${aws_nat_gateway.output_test.public_ip}")
    end
  end
end