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

# Load aws_kms_key resource and types for testing
require 'pangea/resources/aws_kms_key/resource'
require 'pangea/resources/aws_kms_key/types'

RSpec.describe "aws_kms_key resource function" do
  # Create a test class that includes the AWS module and mocks terraform-synthesizer
  let(:test_class) do
    Class.new do
      include Pangea::Resources::AWS
      
      # Mock the terraform-synthesizer resource method
      def resource(type, name)
        @resources ||= {}
        resource_data = { type: type, name: name, attributes: {} }
        
        yield if block_given?
        
        @resources["#{type}.#{name}"] = resource_data
        resource_data
      end
      
      # Method missing to capture terraform attributes
      def method_missing(method_name, *args, &block)
        # Don't capture certain methods that might interfere
        return super if [:expect, :be_a, :eq].include?(method_name)
        # For terraform-synthesizer attribute calls, just return the value
        args.first if args.any?
      end
      
      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end
  end
  
  let(:test_instance) { test_class.new }
  
  describe "KmsKeyAttributes validation" do
    it "accepts minimal configuration with required description" do
      attrs = Pangea::Resources::AWS::Types::KmsKeyAttributes.new({
        description: "Test KMS key"
      })
      
      expect(attrs.description).to eq("Test KMS key")
      expect(attrs.key_usage).to eq('ENCRYPT_DECRYPT')
      expect(attrs.key_spec).to eq('SYMMETRIC_DEFAULT')
      expect(attrs.enable_key_rotation).to eq(false)
      expect(attrs.multi_region).to eq(false)
    end
    
    it "accepts custom key usage and spec" do
      attrs = Pangea::Resources::AWS::Types::KmsKeyAttributes.new({
        description: "Signing key",
        key_usage: 'SIGN_VERIFY',
        key_spec: 'RSA_2048'
      })
      
      expect(attrs.key_usage).to eq('SIGN_VERIFY')
      expect(attrs.key_spec).to eq('RSA_2048')
    end
    
    it "validates key usage enum values" do
      expect {
        Pangea::Resources::AWS::Types::KmsKeyAttributes.new({
          description: "Test key",
          key_usage: 'INVALID_USAGE'
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates key spec enum values" do
      expect {
        Pangea::Resources::AWS::Types::KmsKeyAttributes.new({
          description: "Test key",
          key_spec: 'INVALID_SPEC'
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates key usage and spec compatibility" do
      # SIGN_VERIFY requires asymmetric key
      expect {
        Pangea::Resources::AWS::Types::KmsKeyAttributes.new({
          description: "Invalid combination",
          key_usage: 'SIGN_VERIFY',
          key_spec: 'SYMMETRIC_DEFAULT'
        })
      }.to raise_error(Dry::Struct::Error, /not valid for SIGN_VERIFY usage/)
    end
    
    it "validates key rotation compatibility" do
      # Key rotation only supported for symmetric keys
      expect {
        Pangea::Resources::AWS::Types::KmsKeyAttributes.new({
          description: "Asymmetric key with rotation",
          key_spec: 'RSA_2048',
          enable_key_rotation: true
        })
      }.to raise_error(Dry::Struct::Error, /Key rotation is only supported for SYMMETRIC_DEFAULT/)
    end
    
    it "validates deletion window range" do
      # Valid range
      attrs = Pangea::Resources::AWS::Types::KmsKeyAttributes.new({
        description: "Test key",
        deletion_window_in_days: 15
      })
      expect(attrs.deletion_window_in_days).to eq(15)
      
      # Too short
      expect {
        Pangea::Resources::AWS::Types::KmsKeyAttributes.new({
          description: "Test key",
          deletion_window_in_days: 5
        })
      }.to raise_error(Dry::Types::ConstraintError)
      
      # Too long
      expect {
        Pangea::Resources::AWS::Types::KmsKeyAttributes.new({
          description: "Test key",
          deletion_window_in_days: 35
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "provides computed properties for symmetric keys" do
      attrs = Pangea::Resources::AWS::Types::KmsKeyAttributes.new({
        description: "Symmetric encryption key",
        key_spec: 'SYMMETRIC_DEFAULT',
        key_usage: 'ENCRYPT_DECRYPT',
        enable_key_rotation: true
      })
      
      expect(attrs.is_symmetric?).to eq(true)
      expect(attrs.is_asymmetric?).to eq(false)
      expect(attrs.supports_encryption?).to eq(true)
      expect(attrs.supports_signing?).to eq(false)
      expect(attrs.supports_rotation?).to eq(true)
      expect(attrs.key_algorithm_family).to eq('AES')
    end
    
    it "provides computed properties for RSA keys" do
      attrs = Pangea::Resources::AWS::Types::KmsKeyAttributes.new({
        description: "RSA signing key",
        key_spec: 'RSA_2048',
        key_usage: 'SIGN_VERIFY'
      })
      
      expect(attrs.is_symmetric?).to eq(false)
      expect(attrs.is_asymmetric?).to eq(true)
      expect(attrs.supports_encryption?).to eq(false)
      expect(attrs.supports_signing?).to eq(true)
      expect(attrs.supports_rotation?).to eq(false)
      expect(attrs.key_algorithm_family).to eq('RSA')
    end
    
    it "provides computed properties for ECC keys" do
      attrs = Pangea::Resources::AWS::Types::KmsKeyAttributes.new({
        description: "ECC signing key",
        key_spec: 'ECC_NIST_P256',
        key_usage: 'SIGN_VERIFY'
      })
      
      expect(attrs.is_asymmetric?).to eq(true)
      expect(attrs.supports_signing?).to eq(true)
      expect(attrs.key_algorithm_family).to eq('ECC')
    end
    
    it "calculates estimated monthly cost" do
      # Single-region key
      attrs1 = Pangea::Resources::AWS::Types::KmsKeyAttributes.new({
        description: "Single region key",
        multi_region: false
      })
      expect(attrs1.estimated_monthly_cost).to eq(1.00)
      
      # Multi-region key
      attrs2 = Pangea::Resources::AWS::Types::KmsKeyAttributes.new({
        description: "Multi-region key",
        multi_region: true
      })
      expect(attrs2.estimated_monthly_cost).to eq(2.00)
    end
  end
  
  describe "aws_kms_key function behavior" do
    it "creates a key with minimal attributes" do
      ref = test_instance.aws_kms_key(:test_key, {
        description: "Test KMS key"
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_kms_key')
      expect(ref.name).to eq(:test_key)
    end
    
    it "creates a symmetric encryption key with rotation" do
      ref = test_instance.aws_kms_key(:app_key, {
        description: "Application encryption key",
        key_usage: 'ENCRYPT_DECRYPT',
        key_spec: 'SYMMETRIC_DEFAULT',
        enable_key_rotation: true,
        deletion_window_in_days: 14
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:description]).to eq("Application encryption key")
      expect(attrs[:enable_key_rotation]).to eq(true)
      expect(attrs[:deletion_window_in_days]).to eq(14)
    end
    
    it "creates an asymmetric signing key" do
      ref = test_instance.aws_kms_key(:signing_key, {
        description: "Code signing key",
        key_usage: 'SIGN_VERIFY',
        key_spec: 'RSA_4096'
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:key_usage]).to eq('SIGN_VERIFY')
      expect(attrs[:key_spec]).to eq('RSA_4096')
    end
    
    it "creates a multi-region key" do
      ref = test_instance.aws_kms_key(:global_key, {
        description: "Global data encryption key",
        multi_region: true,
        enable_key_rotation: true
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:multi_region]).to eq(true)
    end
    
    it "creates a key with custom policy" do
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
      
      ref = test_instance.aws_kms_key(:policy_key, {
        description: "Key with custom policy",
        policy: JSON.generate(policy),
        bypass_policy_lockout_safety_check: true
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:policy]).to eq(JSON.generate(policy))
      expect(attrs[:bypass_policy_lockout_safety_check]).to eq(true)
    end
    
    it "creates a key with tags" do
      ref = test_instance.aws_kms_key(:tagged_key, {
        description: "Tagged KMS key",
        tags: {
          Environment: "production",
          Application: "web-app",
          DataClassification: "sensitive"
        }
      })
      
      expect(ref.resource_attributes[:tags]).to eq({
        Environment: "production",
        Application: "web-app",
        DataClassification: "sensitive"
      })
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_kms_key(:test_key, {
        description: "Test key"
      })
      
      expected_outputs = [:id, :arn, :key_id, :description, :key_usage, :key_spec, 
                         :policy, :deletion_window_in_days, :enable_key_rotation, :multi_region]
      
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_kms_key.test_key.")
      end
    end
    
    it "provides computed properties" do
      ref = test_instance.aws_kms_key(:symmetric_key, {
        description: "Symmetric encryption key",
        key_spec: 'SYMMETRIC_DEFAULT',
        key_usage: 'ENCRYPT_DECRYPT',
        enable_key_rotation: true,
        multi_region: true
      })
      
      expect(ref.supports_encryption?).to eq(true)
      expect(ref.supports_signing?).to eq(false)
      expect(ref.is_symmetric?).to eq(true)
      expect(ref.is_asymmetric?).to eq(false)
      expect(ref.supports_rotation?).to eq(true)
      expect(ref.key_algorithm_family).to eq('AES')
      expect(ref.estimated_monthly_cost).to eq(2.00)
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_kms_key(:test_key, {
        description: "Test key"
      })
      
      expect(ref.outputs[:id]).to eq("${aws_kms_key.test_key.id}")
      expect(ref.outputs[:arn]).to eq("${aws_kms_key.test_key.arn}")
      expect(ref.outputs[:key_id]).to eq("${aws_kms_key.test_key.key_id}")
    end
    
    it "can be used with other AWS resources" do
      key_ref = test_instance.aws_kms_key(:data_key, {
        description: "Data encryption key"
      })
      
      # Simulate using key reference for encryption
      key_id = key_ref.outputs[:key_id]
      key_arn = key_ref.outputs[:arn]
      
      expect(key_id).to eq("${aws_kms_key.data_key.key_id}")
      expect(key_arn).to eq("${aws_kms_key.data_key.arn}")
    end
  end
  
  describe "error conditions and edge cases" do
    it "handles string keys in attributes" do
      ref = test_instance.aws_kms_key(:string_keys, {
        "description" => "String key test",
        "key_usage" => "ENCRYPT_DECRYPT",
        "enable_key_rotation" => true
      })
      
      expect(ref.resource_attributes[:description]).to eq("String key test")
      expect(ref.resource_attributes[:key_usage]).to eq("ENCRYPT_DECRYPT")
      expect(ref.resource_attributes[:enable_key_rotation]).to eq(true)
    end
    
    it "validates all RSA key specs for signing" do
      rsa_specs = ['RSA_2048', 'RSA_3072', 'RSA_4096']
      
      rsa_specs.each do |spec|
        attrs = Pangea::Resources::AWS::Types::KmsKeyAttributes.new({
          description: "RSA #{spec} signing key",
          key_usage: 'SIGN_VERIFY',
          key_spec: spec
        })
        
        expect(attrs.key_spec).to eq(spec)
        expect(attrs.key_algorithm_family).to eq('RSA')
      end
    end
    
    it "validates all ECC key specs for signing" do
      ecc_specs = ['ECC_NIST_P256', 'ECC_NIST_P384', 'ECC_NIST_P521', 'ECC_SECG_P256K1']
      
      ecc_specs.each do |spec|
        attrs = Pangea::Resources::AWS::Types::KmsKeyAttributes.new({
          description: "ECC #{spec} signing key",
          key_usage: 'SIGN_VERIFY',
          key_spec: spec
        })
        
        expect(attrs.key_spec).to eq(spec)
        expect(attrs.key_algorithm_family).to eq('ECC')
      end
    end
  end
  
  describe "common KMS key patterns" do
    it "creates a standard application encryption key" do
      ref = test_instance.aws_kms_key(:app_encryption, {
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
      
      expect(ref.is_symmetric?).to eq(true)
      expect(ref.supports_rotation?).to eq(true)
    end
    
    it "creates a database encryption key" do
      ref = test_instance.aws_kms_key(:rds_key, {
        description: "RDS database encryption key",
        key_usage: 'ENCRYPT_DECRYPT',
        key_spec: 'SYMMETRIC_DEFAULT',
        enable_key_rotation: true,
        multi_region: false,
        tags: {
          Service: "RDS",
          Purpose: "database-encryption"
        }
      })
      
      expect(ref.supports_encryption?).to eq(true)
      expect(ref.estimated_monthly_cost).to eq(1.00)
    end
    
    it "creates a code signing key" do
      ref = test_instance.aws_kms_key(:code_signing, {
        description: "Code signing key for Lambda functions",
        key_usage: 'SIGN_VERIFY',
        key_spec: 'RSA_2048',
        tags: {
          Purpose: "code-signing",
          Service: "Lambda"
        }
      })
      
      expect(ref.supports_signing?).to eq(true)
      expect(ref.supports_rotation?).to eq(false)
    end
    
    it "creates a multi-region replication key" do
      ref = test_instance.aws_kms_key(:replication_key, {
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
      
      expect(ref.resource_attributes[:multi_region]).to eq(true)
      expect(ref.estimated_monthly_cost).to eq(2.00)
    end
  end
end