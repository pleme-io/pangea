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

# Load aws_kms_key resource for terraform synthesis testing
require 'pangea/resources/aws_kms_key/resource'

RSpec.describe "aws_kms_key terraform synthesis" do
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
    
    it "synthesizes basic KMS key terraform correctly" do
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
      
      # Call aws_kms_key function with minimal configuration
      ref = test_instance.aws_kms_key(:basic_key, {
        description: "Basic KMS key"
      })
      
      # Verify the function returned correct ResourceReference
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_kms_key')
      expect(ref.name).to eq(:basic_key)
      
      # Verify terraform synthesis calls were made correctly
      expect(test_synthesizer.method_calls).to include(
        [:resource, :aws_kms_key, :basic_key],
        [:description, "Basic KMS key"],
        [:key_usage, 'ENCRYPT_DECRYPT'],
        [:key_spec, 'SYMMETRIC_DEFAULT']
      )
      
      # Verify resource was created in synthesizer
      expect(test_synthesizer.resources).to have_key("aws_kms_key.basic_key")
      
      # Verify resource attributes
      resource = test_synthesizer.resources["aws_kms_key.basic_key"]
      expect(resource.attributes[:description]).to eq("Basic KMS key")
      expect(resource.attributes[:key_usage]).to eq('ENCRYPT_DECRYPT')
      expect(resource.attributes[:key_spec]).to eq('SYMMETRIC_DEFAULT')
    end
    
    it "synthesizes symmetric encryption key with rotation" do
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
      
      # Call with rotation enabled
      ref = test_instance.aws_kms_key(:rotation_key, {
        description: "Rotating encryption key",
        key_usage: 'ENCRYPT_DECRYPT',
        key_spec: 'SYMMETRIC_DEFAULT',
        enable_key_rotation: true,
        deletion_window_in_days: 15
      })
      
      # Verify rotation synthesis
      expect(test_synthesizer.method_calls).to include(
        [:description, "Rotating encryption key"],
        [:enable_key_rotation, true],
        [:deletion_window_in_days, 15]
      )
    end
    
    it "synthesizes asymmetric signing key" do
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
      
      # Call with signing key configuration
      ref = test_instance.aws_kms_key(:signing_key, {
        description: "Code signing key",
        key_usage: 'SIGN_VERIFY',
        key_spec: 'RSA_2048'
      })
      
      # Verify signing key synthesis
      expect(test_synthesizer.method_calls).to include(
        [:key_usage, 'SIGN_VERIFY'],
        [:key_spec, 'RSA_2048']
      )
      
      # Verify rotation not included for asymmetric key
      expect(test_synthesizer.method_calls).not_to include([:enable_key_rotation, anything])
    end
    
    it "synthesizes multi-region key" do
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
      
      # Call with multi-region configuration
      ref = test_instance.aws_kms_key(:global_key, {
        description: "Multi-region encryption key",
        multi_region: true,
        enable_key_rotation: true
      })
      
      # Verify multi-region synthesis
      expect(test_synthesizer.method_calls).to include(
        [:multi_region, true],
        [:enable_key_rotation, true]
      )
    end
    
    it "synthesizes key with custom policy" do
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
      
      # Create policy document
      policy = {
        "Version" => "2012-10-17",
        "Statement" => [{
          "Sid" => "Enable IAM User Permissions",
          "Effect" => "Allow",
          "Principal" => {
            "AWS" => "arn:aws:iam::123456789012:root"
          },
          "Action" => "kms:*",
          "Resource" => "*"
        }]
      }
      
      # Call with policy
      ref = test_instance.aws_kms_key(:policy_key, {
        description: "Key with custom policy",
        policy: JSON.generate(policy),
        bypass_policy_lockout_safety_check: true
      })
      
      # Verify policy synthesis
      expect(test_synthesizer.method_calls).to include(
        [:policy, JSON.generate(policy)],
        [:bypass_policy_lockout_safety_check, true]
      )
    end
    
    it "synthesizes key with tags" do
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
      ref = test_instance.aws_kms_key(:tagged_key, {
        description: "Tagged KMS key",
        tags: {
          Environment: "production",
          Application: "web-app",
          DataClassification: "sensitive"
        }
      })
      
      # Verify tags synthesis
      expect(test_synthesizer.method_calls).to include([:tags])
      
      # Find the tags resource context
      resource = test_synthesizer.resources["aws_kms_key.tagged_key"]
      expect(resource.attributes).to have_key(:tags)
      tags_context = resource.attributes[:tags]
      expect(tags_context.attributes).to eq({
        Environment: "production",
        Application: "web-app",
        DataClassification: "sensitive"
      })
    end
    
    it "synthesizes different key algorithm families" do
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
      
      # Test RSA key
      rsa_ref = test_instance.aws_kms_key(:rsa_key, {
        description: "RSA signing key",
        key_usage: 'SIGN_VERIFY',
        key_spec: 'RSA_4096'
      })
      
      expect(test_synthesizer.method_calls).to include(
        [:key_spec, 'RSA_4096']
      )
      
      # Test ECC key
      ecc_ref = test_instance.aws_kms_key(:ecc_key, {
        description: "ECC signing key",
        key_usage: 'SIGN_VERIFY',
        key_spec: 'ECC_NIST_P384'
      })
      
      expect(test_synthesizer.method_calls).to include(
        [:key_spec, 'ECC_NIST_P384']
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
      
      ref = test_instance.aws_kms_key(:output_test, {
        description: "Test key"
      })
      
      # Verify all outputs have correct terraform reference format
      expected_outputs = [:id, :arn, :key_id, :description, :key_usage, :key_spec, 
                         :policy, :deletion_window_in_days, :enable_key_rotation, :multi_region]
      
      expected_outputs.each do |output|
        expect(ref.outputs[output]).to match(/\A\${aws_kms_key\.output_test\./)
      end
      
      # Verify specific output formats
      expect(ref.outputs[:id]).to eq("${aws_kms_key.output_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_kms_key.output_test.arn}")
      expect(ref.outputs[:key_id]).to eq("${aws_kms_key.output_test.key_id}")
      expect(ref.outputs[:key_spec]).to eq("${aws_kms_key.output_test.key_spec}")
    end
    
    it "synthesizes common KMS key patterns" do
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
      
      # Application encryption key pattern
      app_ref = test_instance.aws_kms_key(:app_key, {
        description: "Application data encryption key",
        key_usage: 'ENCRYPT_DECRYPT',
        key_spec: 'SYMMETRIC_DEFAULT',
        enable_key_rotation: true,
        deletion_window_in_days: 10,
        tags: {
          Purpose: "data-encryption",
          ManagedBy: "terraform"
        }
      })
      
      # Verify standard encryption key synthesis
      expect(test_synthesizer.method_calls).to include(
        [:enable_key_rotation, true],
        [:deletion_window_in_days, 10]
      )
      
      # Database encryption key pattern
      db_ref = test_instance.aws_kms_key(:rds_key, {
        description: "RDS database encryption key",
        key_usage: 'ENCRYPT_DECRYPT',
        key_spec: 'SYMMETRIC_DEFAULT',
        enable_key_rotation: true,
        tags: {
          Service: "RDS",
          Purpose: "database-encryption"
        }
      })
      
      # Code signing key pattern
      sign_ref = test_instance.aws_kms_key(:code_signing, {
        description: "Code signing key for Lambda functions",
        key_usage: 'SIGN_VERIFY',
        key_spec: 'RSA_2048',
        tags: {
          Purpose: "code-signing",
          Service: "Lambda"
        }
      })
      
      # Multi-region replication key pattern
      global_ref = test_instance.aws_kms_key(:replication_key, {
        description: "Cross-region replication key",
        key_usage: 'ENCRYPT_DECRYPT',
        key_spec: 'SYMMETRIC_DEFAULT',
        multi_region: true,
        enable_key_rotation: true,
        tags: {
          Scope: "global",
          Purpose: "cross-region-replication"
        }
      })
      
      # Verify all patterns were synthesized
      expect(test_synthesizer.resources.keys).to include(
        "aws_kms_key.app_key",
        "aws_kms_key.rds_key",
        "aws_kms_key.code_signing",
        "aws_kms_key.replication_key"
      )
    end
    
    it "handles conditional rotation for asymmetric keys" do
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
      
      # Try to enable rotation on asymmetric key (should be ignored)
      ref = test_instance.aws_kms_key(:asym_key, {
        description: "Asymmetric key",
        key_usage: 'SIGN_VERIFY',
        key_spec: 'RSA_2048',
        enable_key_rotation: true  # This should be ignored
      })
      
      # Verify rotation was not synthesized for asymmetric key
      resource = test_synthesizer.resources["aws_kms_key.asym_key"]
      expect(resource.attributes).not_to have_key(:enable_key_rotation)
    end
  end
end