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

# Load aws_route_table resource for terraform synthesis testing
require 'pangea/resources/aws_route_table/resource'

RSpec.describe "aws_route_table terraform synthesis" do
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
            # For nested blocks like route and tags
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
              # For nested blocks like route and tags
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
    let(:vpc_id) { "${aws_vpc.test.id}" }
    let(:igw_id) { "${aws_internet_gateway.test.id}" }
    let(:nat_id) { "${aws_nat_gateway.test.id}" }
    
    it "synthesizes basic route table terraform correctly" do
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
      
      # Call aws_route_table function with minimal configuration
      ref = test_instance.aws_route_table(:basic_rt, {
        vpc_id: vpc_id
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_route_table')
      expect(ref.name).to eq(:basic_rt)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_route_table, :basic_rt],
        [:vpc_id, vpc_id]
      )
      
      # Verify no route blocks were called (empty routes)
      route_calls = test_synthesizer.method_calls.select { |call| call[0] == :route }
      expect(route_calls).to be_empty
      
      # Verify tags block was NOT called (since no tags provided)
      tags_calls = test_synthesizer.method_calls.select { |call| call[0] == :tags }
      expect(tags_calls).to be_empty
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_route_table.basic_rt")
    end
    
    it "synthesizes route table with single route correctly" do
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
      
      # Call aws_route_table function with internet gateway route
      ref = test_instance.aws_route_table(:public_rt, {
        vpc_id: vpc_id,
        routes: [
          {
            cidr_block: "0.0.0.0/0",
            gateway_id: igw_id
          }
        ]
      })
      
      # Verify basic synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_route_table, :public_rt],
        [:vpc_id, vpc_id]
      )
      
      # Verify route block was called
      expect(test_synthesizer.method_calls).to include([:route])
      
      # Verify route attributes were processed
      expect(test_synthesizer.method_calls).to include(
        [:cidr_block, "0.0.0.0/0"],
        [:gateway_id, igw_id]
      )
      
      # Verify other route attributes were NOT called
      nat_calls = test_synthesizer.method_calls.select { |call| call[0] == :nat_gateway_id }
      expect(nat_calls).to be_empty
    end
    
    it "synthesizes route table with multiple routes correctly" do
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
      
      # Call aws_route_table function with multiple routes
      ref = test_instance.aws_route_table(:multi_rt, {
        vpc_id: vpc_id,
        routes: [
          {
            cidr_block: "0.0.0.0/0",
            gateway_id: igw_id
          },
          {
            cidr_block: "10.1.0.0/16",
            vpc_peering_connection_id: "${aws_vpc_peering_connection.test.id}"
          }
        ]
      })
      
      # Verify basic synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_route_table, :multi_rt],
        [:vpc_id, vpc_id]
      )
      
      # Verify route block was called twice
      route_calls = test_synthesizer.method_calls.select { |call| call[0] == :route }
      expect(route_calls.length).to eq(2)
      
      # Verify both routes' attributes were processed
      expect(test_synthesizer.method_calls).to include(
        [:cidr_block, "0.0.0.0/0"],
        [:gateway_id, igw_id],
        [:cidr_block, "10.1.0.0/16"],
        [:vpc_peering_connection_id, "${aws_vpc_peering_connection.test.id}"]
      )
    end
    
    it "synthesizes route table with NAT gateway route correctly" do
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
      
      # Call aws_route_table function with NAT gateway route
      ref = test_instance.aws_route_table(:private_rt, {
        vpc_id: vpc_id,
        routes: [
          {
            cidr_block: "0.0.0.0/0",
            nat_gateway_id: nat_id
          }
        ]
      })
      
      # Verify NAT route synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_route_table, :private_rt],
        [:vpc_id, vpc_id],
        [:route]
      )
      
      # Verify NAT gateway route attributes
      expect(test_synthesizer.method_calls).to include(
        [:cidr_block, "0.0.0.0/0"],
        [:nat_gateway_id, nat_id]
      )
      
      # Verify other route targets were NOT called
      gateway_calls = test_synthesizer.method_calls.select { |call| call[0] == :gateway_id }
      expect(gateway_calls).to be_empty
    end
    
    it "synthesizes route table with IPv6 routes correctly" do
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
      
      # Call aws_route_table function with IPv6 route
      ref = test_instance.aws_route_table(:ipv6_rt, {
        vpc_id: vpc_id,
        routes: [
          {
            ipv6_cidr_block: "::/0",
            egress_only_gateway_id: "${aws_egress_only_internet_gateway.test.id}"
          }
        ]
      })
      
      # Verify IPv6 route synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_route_table, :ipv6_rt],
        [:vpc_id, vpc_id],
        [:route]
      )
      
      # Verify IPv6 route attributes
      expect(test_synthesizer.method_calls).to include(
        [:ipv6_cidr_block, "::/0"],
        [:egress_only_gateway_id, "${aws_egress_only_internet_gateway.test.id}"]
      )
      
      # Verify IPv4 CIDR was NOT called
      cidr_calls = test_synthesizer.method_calls.select { |call| call[0] == :cidr_block }
      expect(cidr_calls).to be_empty
    end
    
    it "synthesizes route table with transit gateway routes correctly" do
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
      
      tgw_id = "${aws_ec2_transit_gateway.test.id}"
      
      # Call aws_route_table function with transit gateway routes
      ref = test_instance.aws_route_table(:transit_rt, {
        vpc_id: vpc_id,
        routes: [
          {
            cidr_block: "192.168.0.0/16",
            transit_gateway_id: tgw_id
          },
          {
            cidr_block: "172.16.0.0/12",
            transit_gateway_id: tgw_id
          }
        ]
      })
      
      # Verify transit gateway routes synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_route_table, :transit_rt],
        [:vpc_id, vpc_id]
      )
      
      # Verify two route blocks were called
      route_calls = test_synthesizer.method_calls.select { |call| call[0] == :route }
      expect(route_calls.length).to eq(2)
      
      # Verify transit gateway route attributes
      expect(test_synthesizer.method_calls).to include(
        [:cidr_block, "192.168.0.0/16"],
        [:transit_gateway_id, tgw_id],
        [:cidr_block, "172.16.0.0/12"],
        [:transit_gateway_id, tgw_id]
      )
    end
    
    it "synthesizes route table with tags correctly" do
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
      
      # Call aws_route_table function with tags
      ref = test_instance.aws_route_table(:tagged_rt, {
        vpc_id: vpc_id,
        routes: [
          {
            cidr_block: "0.0.0.0/0",
            gateway_id: igw_id
          }
        ],
        tags: {
          Name: "public-route-table",
          Environment: "production",
          Type: "public",
          ManagedBy: "pangea"
        }
      })
      
      # Verify basic synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_route_table, :tagged_rt],
        [:vpc_id, vpc_id],
        [:route]
      )
      
      # Verify tags block was called
      expect(test_synthesizer.method_calls).to include([:tags])
      expect(test_synthesizer.method_calls).to include([:Name, "public-route-table"])
      expect(test_synthesizer.method_calls).to include([:Environment, "production"])
      expect(test_synthesizer.method_calls).to include([:Type, "public"])
      expect(test_synthesizer.method_calls).to include([:ManagedBy, "pangea"])
    end
    
    it "synthesizes route table for multi-environment deployment" do
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
      
      # Simulate creating route tables for multiple environments
      environments = [
        { name: "dev", vpc: "${aws_vpc.dev.id}", igw: "${aws_internet_gateway.dev.id}" },
        { name: "prod", vpc: "${aws_vpc.prod.id}", igw: "${aws_internet_gateway.prod.id}" }
      ]
      
      environments.each do |env|
        ref = test_instance.aws_route_table(:"#{env[:name]}_public_rt", {
          vpc_id: env[:vpc],
          routes: [
            {
              cidr_block: "0.0.0.0/0",
              gateway_id: env[:igw]
            }
          ],
          tags: {
            Name: "#{env[:name]}-public-rt",
            Environment: env[:name],
            Type: "public"
          }
        })
        
        # Verify each environment's synthesis
        expect(test_synthesizer.method_calls).to include(
          [:resource, :aws_route_table, :"#{env[:name]}_public_rt"],
          [:vpc_id, env[:vpc]],
          [:gateway_id, env[:igw]],
          [:Name, "#{env[:name]}-public-rt"],
          [:Environment, env[:name]]
        )
      end
    end
    
    it "handles empty routes array correctly" do
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
      
      # Call with explicit empty routes array
      ref = test_instance.aws_route_table(:empty_routes_rt, {
        vpc_id: vpc_id,
        routes: [],
        tags: { Name: "empty-routes-rt" }
      })
      
      # Verify synthesis
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_route_table, :empty_routes_rt],
        [:vpc_id, vpc_id]
      )
      
      # Verify no route blocks were called for empty array
      route_calls = test_synthesizer.method_calls.select { |call| call[0] == :route }
      expect(route_calls).to be_empty
      
      # Verify tags were still processed
      expect(test_synthesizer.method_calls).to include(
        [:tags],
        [:Name, "empty-routes-rt"]
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
      
      ref = test_instance.aws_route_table(:output_test, {
        vpc_id: vpc_id,
        routes: [
          {
            cidr_block: "0.0.0.0/0",
            gateway_id: igw_id
          }
        ],
        tags: { Name: "output-test-rt" }
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :arn, :owner_id, :route_table_id]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\$\{aws_route_table\.output_test\./)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_route_table.output_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_route_table.output_test.arn}")
      expect(ref.outputs[:owner_id]).to eq("${aws_route_table.output_test.owner_id}")
      expect(ref.outputs[:route_table_id]).to eq("${aws_route_table.output_test.id}")
    end
  end
end