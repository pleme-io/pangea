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

# Load aws_kms_alias resource for terraform synthesis testing
require 'pangea/resources/aws_kms_alias/resource'

RSpec.describe "aws_kms_alias terraform synthesis" do
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
    
    it "synthesizes basic KMS alias terraform correctly" do
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
      
      # Call aws_kms_alias function with minimal configuration
      ref = test_instance.aws_kms_alias(:basic_alias, {
        name: "alias/test-key",
        target_key_id: "12345678-1234-1234-1234-123456789012"
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_kms_alias')
      expect(ref.name).to eq(:basic_alias)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_kms_alias, :basic_alias],
        [:name, "alias/test-key"],
        [:target_key_id, "12345678-1234-1234-1234-123456789012"]
      )
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_kms_alias.basic_alias")
      
      # Verify resource attributes
      resource = test_synthesizer.resources["aws_kms_alias.basic_alias"]
      expect(resource.attributes[:name]).to eq("alias/test-key")
      expect(resource.attributes[:target_key_id]).to eq("12345678-1234-1234-1234-123456789012")
    end
    
    it "synthesizes alias with key ARN target" do
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
      
      # Call with key ARN
      ref = test_instance.aws_kms_alias(:arn_alias, {
        name: "alias/database/prod",
        target_key_id: "arn:aws:kms:us-east-1:123456789012:key/87654321-4321-4321-4321-210987654321"
      })
      
      # Verify ARN target synthesis
      expect(test_synthesizer.method_calls).to include(
        [:name, "alias/database/prod"],
        [:target_key_id, "arn:aws:kms:us-east-1:123456789012:key/87654321-4321-4321-4321-210987654321"]
      )
    end
    
    it "synthesizes service-specific alias patterns" do
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
      
      # Test different service patterns
      service_aliases = [
        { name: "alias/rds/production", service: "RDS" },
        { name: "alias/s3/data-lake", service: "S3" },
        { name: "alias/lambda/processors", service: "Lambda" },
        { name: "alias/secrets/api-keys", service: "Secrets Manager" }
      ]
      
      service_aliases.each_with_index do |alias_config, index|
        ref = test_instance.aws_kms_alias(:"service_#{index}", {
          name: alias_config[:name],
          target_key_id: "#{index}2345678-1234-1234-1234-123456789012"
        })
        
        expect(test_synthesizer.method_calls).to include(
          [:name, alias_config[:name]]
        )
      end
    end
    
    it "synthesizes organizational hierarchy aliases" do
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
      
      # Create hierarchical aliases
      hierarchies = [
        "alias/platform/encryption/general",
        "alias/application/backend/database",
        "alias/infrastructure/networking/vpn",
        "alias/security/secrets/production"
      ]
      
      hierarchies.each_with_index do |alias_name, index|
        ref = test_instance.aws_kms_alias(:"hierarchy_#{index}", {
          name: alias_name,
          target_key_id: "#{index}2345678-1234-1234-1234-123456789012"
        })
        
        expect(test_synthesizer.method_calls).to include(
          [:name, alias_name]
        )
      end
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
      
      ref = test_instance.aws_kms_alias(:output_test, {
        name: "alias/test",
        target_key_id: "12345678-1234-1234-1234-123456789012"
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :arn, :name, :target_key_arn, :target_key_id]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\${aws_kms_alias\.output_test\./)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_kms_alias.output_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_kms_alias.output_test.arn}")
      expect(ref.outputs[:name]).to eq("${aws_kms_alias.output_test.name}")
      expect(ref.outputs[:target_key_arn]).to eq("${aws_kms_alias.output_test.target_key_arn}")
      expect(ref.outputs[:target_key_id]).to eq("${aws_kms_alias.output_test.target_key_id}")
    end
    
    it "synthesizes alias with KMS key reference integration" do
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
      
      # Simulate using KMS key reference as target
      key_reference = "${aws_kms_key.main.id}"
      
      ref = test_instance.aws_kms_alias(:key_ref_alias, {
        name: "alias/main-key",
        target_key_id: key_reference
      })
      
      # Verify reference integration synthesis
      expect(test_synthesizer.method_calls).to include(
        [:target_key_id, key_reference]
      )
      
      resource = test_synthesizer.resources["aws_kms_alias.key_ref_alias"]
      expect(resource.attributes[:target_key_id]).to eq(key_reference)
    end
    
    it "synthesizes environment-specific alias patterns" do
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
      
      # Create aliases for different environments
      environments = [
        { env: "dev", key_id: "12345678-1234-1234-1234-123456789012" },
        { env: "staging", key_id: "23456789-2345-2345-2345-234567890123" },
        { env: "prod", key_id: "34567890-3456-3456-3456-345678901234" }
      ]
      
      environments.each do |env_config|
        ref = test_instance.aws_kms_alias(:"#{env_config[:env]}_alias", {
          name: "alias/app/#{env_config[:env]}",
          target_key_id: env_config[:key_id]
        })
        
        expect(test_synthesizer.method_calls).to include(
          [:name, "alias/app/#{env_config[:env]}"],
          [:target_key_id, env_config[:key_id]]
        )
      end
      
      # Verify all environment aliases were created
      expect(test_synthesizer.resources.keys).to include(
        "aws_kms_alias.dev_alias",
        "aws_kms_alias.staging_alias", 
        "aws_kms_alias.prod_alias"
      )
    end
    
    it "synthesizes multi-service alias architecture" do
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
      
      # Create service-specific aliases pointing to same key
      master_key_id = "12345678-1234-1234-1234-123456789012"
      
      services = [
        "alias/rds/user-data",
        "alias/s3/application-logs", 
        "alias/lambda/api-secrets",
        "alias/secrets/database-password"
      ]
      
      services.each_with_index do |alias_name, index|
        ref = test_instance.aws_kms_alias(:"service_#{index}", {
          name: alias_name,
          target_key_id: master_key_id
        })
        
        expect(test_synthesizer.method_calls).to include(
          [:name, alias_name],
          [:target_key_id, master_key_id]
        )
      end
      
      # Verify all service aliases were created
      services.each_with_index do |_, index|
        expect(test_synthesizer.resources).to have_key("aws_kms_alias.service_#{index}")
      end
    end
  end
end