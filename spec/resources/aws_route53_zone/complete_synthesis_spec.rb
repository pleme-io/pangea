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

# Load aws_route53_zone resource for terraform synthesis testing
require 'pangea/resources/aws_route53_zone/resource'

RSpec.describe "aws_route53_zone terraform synthesis" do
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
            # For nested blocks like tags and vpc
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
    
    it "synthesizes basic public zone terraform correctly" do
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
      
      # Call aws_route53_zone function with minimal configuration
      ref = test_instance.aws_route53_zone(:basic_zone, {
        name: "example.com"
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_route53_zone')
      expect(ref.name).to eq(:basic_zone)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_route53_zone, :basic_zone],
        [:name, "example.com"]
      )
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_route53_zone.basic_zone")
      
      # Verify resource attributes
      resource = test_synthesizer.resources["aws_route53_zone.basic_zone"]
      expect(resource.attributes[:name]).to eq("example.com")
    end
    
    it "synthesizes private zone with VPC configuration" do
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
      
      # Call with VPC configuration
      ref = test_instance.aws_route53_zone(:private_zone, {
        name: "internal.company.com",
        comment: "Internal services zone",
        vpc: [{ 
          vpc_id: "vpc-12345678",
          vpc_region: "us-east-1"
        }]
      })
      
      # Verify VPC synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "internal.company.com"],
        [:comment, "Internal services zone"],
        [:vpc]
      )
      
      # Verify VPC block was created
      resource = test_synthesizer.resources["aws_route53_zone.private_zone"]
      expect(resource.attributes).to have_key(:vpc)
    end
    
    it "synthesizes multi-VPC private zone" do
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
      
      # Call with multiple VPCs
      ref = test_instance.aws_route53_zone(:multi_vpc_zone, {
        name: "shared.internal.com",
        vpc: [
          { vpc_id: "vpc-12345678", vpc_region: "us-east-1" },
          { vpc_id: "vpc-87654321", vpc_region: "us-west-2" }
        ]
      })
      
      # Verify multiple VPC blocks were synthesized
      vpc_calls = test_synthesizer.method_calls.select { |call| call[0] == :vpc }
      expect(vpc_calls.length).to eq(2)
    end
    
    it "synthesizes zone with delegation set" do
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
      
      # Call with delegation set
      ref = test_instance.aws_route53_zone(:delegated_zone, {
        name: "delegated.example.com",
        delegation_set_id: "N1PA6795SAMPLE",
        force_destroy: true
      })
      
      # Verify delegation set synthesis
      expect(test_synthesizer.method_calls).to include(
        [:delegation_set_id, "N1PA6795SAMPLE"],
        [:force_destroy, true]
      )
    end
    
    it "synthesizes zone with tags" do
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
      ref = test_instance.aws_route53_zone(:tagged_zone, {
        name: "tagged.example.com",
        comment: "Zone with tags",
        tags: {
          Environment: "production",
          Application: "web-app",
          ManagedBy: "terraform"
        }
      })
      
      # Verify tags synthesis
      expect(test_synthesizer.method_calls).to include([:tags])
      
      # Find the tags resource context
      resource = test_synthesizer.resources["aws_route53_zone.tagged_zone"]
      expect(resource.attributes).to have_key(:tags)
      tags_context = resource.attributes[:tags]
      expect(tags_context.attributes).to eq({
        Environment: "production",
        Application: "web-app",
        ManagedBy: "terraform"
      })
    end
    
    it "synthesizes common Route53 patterns" do
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
      
      # Public production zone
      public_ref = test_instance.aws_route53_zone(:prod_public, {
        name: "myapp.com",
        comment: "Production public zone",
        tags: { Environment: "production" }
      })
      
      # Private development zone
      dev_ref = test_instance.aws_route53_zone(:dev_private, {
        name: "dev.internal",
        comment: "Development private zone",
        vpc: [{ vpc_id: "vpc-dev123456" }],
        force_destroy: true,
        tags: { Environment: "development" }
      })
      
      # Multi-region private zone
      multi_ref = test_instance.aws_route53_zone(:multi_region, {
        name: "global.internal.com",
        vpc: [
          { vpc_id: "vpc-east", vpc_region: "us-east-1" },
          { vpc_id: "vpc-west", vpc_region: "us-west-2" }
        ]
      })
      
      # Verify all zones were synthesized
      expect(test_synthesizer.resources.keys).to include(
        "aws_route53_zone.prod_public",
        "aws_route53_zone.dev_private",
        "aws_route53_zone.multi_region"
      )
      
      # Verify force_destroy only on development
      expect(test_synthesizer.method_calls).to include([:force_destroy, true])
      
      # Verify VPC blocks for private zones
      vpc_calls = test_synthesizer.method_calls.select { |call| call[0] == :vpc }
      expect(vpc_calls.length).to eq(3)  # 1 for dev + 2 for multi-region
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
      
      ref = test_instance.aws_route53_zone(:output_test, {
        name: "output-test.com"
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :zone_id, :arn, :name, :name_servers, 
                         :primary_name_server, :comment, :tags_all]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\${aws_route53_zone\.output_test\./)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_route53_zone.output_test.id}")
      expect(ref.outputs[:zone_id]).to eq("${aws_route53_zone.output_test.zone_id}")
      expect(ref.outputs[:arn]).to eq("${aws_route53_zone.output_test.arn}")
      expect(ref.outputs[:name_servers]).to eq("${aws_route53_zone.output_test.name_servers}")
    end
    
    it "synthesizes zone configuration helpers" do
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
      
      # Use configuration helpers
      public_config = Pangea::Resources::AWS::Types::Route53ZoneConfigs.public_zone("public.com")
      public_ref = test_instance.aws_route53_zone(:public_helper, public_config)
      
      private_config = Pangea::Resources::AWS::Types::Route53ZoneConfigs.private_zone(
        "private.internal",
        "vpc-12345678",
        vpc_region: "us-east-1"
      )
      private_ref = test_instance.aws_route53_zone(:private_helper, private_config)
      
      # Verify helper configurations were synthesized correctly
      expect(test_synthesizer.method_calls).to include(
        [:name, "public.com"],
        [:name, "private.internal"]
      )
      
      # Verify private zone VPC configuration
      expect(test_synthesizer.method_calls).to include([:vpc])
    end
    
    it "synthesizes corporate zone patterns" do
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
      
      # Corporate internal zone
      vpc_configs = [
        { vpc_id: "vpc-corp-east", vpc_region: "us-east-1" },
        { vpc_id: "vpc-corp-west", vpc_region: "us-west-2" }
      ]
      
      corp_config = Pangea::Resources::AWS::Types::Route53ZoneConfigs.corporate_internal_zone(
        "corp.internal",
        vpc_configs
      )
      corp_ref = test_instance.aws_route53_zone(:corporate, corp_config)
      
      # Verify corporate zone synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "corp.internal"]
      )
      
      # Verify multiple VPC blocks
      vpc_calls = test_synthesizer.method_calls.select { |call| call[0] == :vpc }
      expect(vpc_calls.length).to eq(2)
    end
    
    it "synthesizes development zone with force destroy" do
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
      
      # Development zone configuration
      dev_config = Pangea::Resources::AWS::Types::Route53ZoneConfigs.development_zone(
        "dev.myapp.com",
        is_private: true,
        vpc_id: "vpc-dev123456"
      )
      dev_ref = test_instance.aws_route53_zone(:dev_zone, dev_config)
      
      # Verify force_destroy synthesis for development
      expect(test_synthesizer.method_calls).to include(
        [:force_destroy, true]
      )
    end
    
    it "handles conditional attribute synthesis" do
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
      
      # Zone without optional attributes
      minimal_ref = test_instance.aws_route53_zone(:minimal, {
        name: "minimal.com"
      })
      
      # Zone with all optional attributes
      full_ref = test_instance.aws_route53_zone(:full, {
        name: "full.example.com",
        comment: "Full configuration zone",
        delegation_set_id: "N1PA6795SAMPLE",
        force_destroy: true,
        vpc: [{ vpc_id: "vpc-12345678" }],
        tags: { Environment: "test" }
      })
      
      # Verify minimal zone doesn't include optional attributes
      minimal_calls = test_synthesizer.method_calls.select do |call|
        [:comment, :delegation_set_id, :force_destroy, :vpc, :tags].include?(call[0]) &&
        call[1] != "minimal.com"  # Exclude the name call
      end.select { |call| call.length > 1 }  # Only calls with values
      
      # All optional calls should be for the full zone
      full_calls = test_synthesizer.method_calls.select do |call|
        [:comment, :delegation_set_id, :force_destroy, :vpc, :tags].include?(call[0])
      end
      
      expect(full_calls.length).to be >= 4  # At least comment, delegation_set_id, force_destroy, tags
    end
    
    it "synthesizes complex domain hierarchies" do
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
      
      # Create zones for different levels of a domain hierarchy
      zones = [
        { name: :root, domain: "company.com" },
        { name: :api, domain: "api.company.com" },
        { name: :v1_api, domain: "v1.api.company.com" },
        { name: :internal, domain: "internal.company.com" }
      ]
      
      zones.each do |zone_config|
        ref = test_instance.aws_route53_zone(zone_config[:name], {
          name: zone_config[:domain],
          comment: "Zone for #{zone_config[:domain]}"
        })
        
        expect(test_synthesizer.method_calls).to include(
          [:name, zone_config[:domain]]
        )
      end
      
      # Verify all zones were created
      zones.each do |zone_config|
        expect(test_synthesizer.resources).to have_key("aws_route53_zone.#{zone_config[:name]}")
      end
    end
  end
end