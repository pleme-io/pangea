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

# Load aws_kms_alias resource and types for testing
require 'pangea/resources/aws_kms_alias/resource'
require 'pangea/resources/aws_kms_alias/types'

RSpec.describe "aws_kms_alias resource function" do
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
  
  describe "KmsAliasAttributes validation" do
    it "accepts valid alias name with key ID" do
      attrs = Pangea::Resources::AWS::Types::KmsAliasAttributes.new({
        name: "alias/my-app-key",
        target_key_id: "12345678-1234-1234-1234-123456789012"
      })
      
      expect(attrs.name).to eq("alias/my-app-key")
      expect(attrs.target_key_id).to eq("12345678-1234-1234-1234-123456789012")
    end
    
    it "accepts valid alias name with key ARN" do
      attrs = Pangea::Resources::AWS::Types::KmsAliasAttributes.new({
        name: "alias/database/prod",
        target_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      })
      
      expect(attrs.name).to eq("alias/database/prod")
      expect(attrs.target_key_id).to eq("arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012")
    end
    
    it "validates alias name must start with 'alias/'" do
      expect {
        Pangea::Resources::AWS::Types::KmsAliasAttributes.new({
          name: "my-app-key",
          target_key_id: "12345678-1234-1234-1234-123456789012"
        })
      }.to raise_error(Dry::Struct::Error, /must start with 'alias\/'/)
    end
    
    it "validates alias name cannot start with 'alias/aws/'" do
      expect {
        Pangea::Resources::AWS::Types::KmsAliasAttributes.new({
          name: "alias/aws/s3",
          target_key_id: "12345678-1234-1234-1234-123456789012"
        })
      }.to raise_error(Dry::Types::ConstraintError, /cannot start with 'alias\/aws\/'/)
    end
    
    it "validates alias name length limits" do
      # Test maximum length (256 characters after alias/)
      long_alias = "alias/" + "a" * 256
      
      expect {
        Pangea::Resources::AWS::Types::KmsAliasAttributes.new({
          name: long_alias + "x",  # 257 characters
          target_key_id: "12345678-1234-1234-1234-123456789012"
        })
      }.to raise_error(Dry::Types::ConstraintError)
      
      # Valid at exactly 256
      attrs = Pangea::Resources::AWS::Types::KmsAliasAttributes.new({
        name: long_alias,
        target_key_id: "12345678-1234-1234-1234-123456789012"
      })
      expect(attrs.name).to eq(long_alias)
    end
    
    it "validates alias name character restrictions" do
      invalid_names = [
        "alias/my key!",        # Space and exclamation
        "alias/my@key",         # @ symbol
        "alias/my%key",         # % symbol
        "alias/my.key"          # Period (not allowed)
      ]
      
      invalid_names.each do |invalid_name|
        expect {
          Pangea::Resources::AWS::Types::KmsAliasAttributes.new({
            name: invalid_name,
            target_key_id: "12345678-1234-1234-1234-123456789012"
          })
        }.to raise_error(Dry::Types::ConstraintError)
      end
    end
    
    it "accepts valid alias name characters" do
      valid_names = [
        "alias/my-app-key",      # Hyphens
        "alias/my_app_key",      # Underscores
        "alias/service/prod",    # Forward slashes
        "alias/APP123",          # Mixed case and numbers
        "alias/a",               # Single character
      ]
      
      valid_names.each do |valid_name|
        attrs = Pangea::Resources::AWS::Types::KmsAliasAttributes.new({
          name: valid_name,
          target_key_id: "12345678-1234-1234-1234-123456789012"
        })
        expect(attrs.name).to eq(valid_name)
      end
    end
    
    it "validates target key ID format" do
      valid_key_ids = [
        "12345678-1234-1234-1234-123456789012",  # Standard key ID
        "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"  # Key ARN
      ]
      
      valid_key_ids.each do |key_id|
        attrs = Pangea::Resources::AWS::Types::KmsAliasAttributes.new({
          name: "alias/test-key",
          target_key_id: key_id
        })
        expect(attrs.target_key_id).to eq(key_id)
      end
    end
    
    it "rejects invalid target key ID formats" do
      invalid_key_ids = [
        "invalid-key-id",
        "12345-short",
        "arn:aws:iam::123456789012:role/test",  # Wrong service
        "not-a-valid-format"
      ]
      
      invalid_key_ids.each do |invalid_key_id|
        expect {
          Pangea::Resources::AWS::Types::KmsAliasAttributes.new({
            name: "alias/test-key",
            target_key_id: invalid_key_id
          })
        }.to raise_error(Dry::Struct::Error, /Invalid target key ID format/)
      end
    end
    
    it "provides computed properties for alias suffix" do
      attrs = Pangea::Resources::AWS::Types::KmsAliasAttributes.new({
        name: "alias/my-app/database",
        target_key_id: "12345678-1234-1234-1234-123456789012"
      })
      
      expect(attrs.alias_suffix).to eq("my-app/database")
      expect(attrs.is_service_alias?).to eq(true)  # Contains slash
    end
    
    it "detects service-specific alias patterns" do
      test_cases = [
        { name: "alias/rds/prod", expected_purpose: "RDS encryption" },
        { name: "alias/s3/bucket", expected_purpose: "S3 bucket encryption" },
        { name: "alias/lambda/func", expected_purpose: "Lambda environment encryption" },
        { name: "alias/secrets/api", expected_purpose: "Secrets Manager encryption" },
        { name: "alias/ebs/volumes", expected_purpose: "EBS volume encryption" },
        { name: "alias/general", expected_purpose: "General purpose encryption" }
      ]
      
      test_cases.each do |test_case|
        attrs = Pangea::Resources::AWS::Types::KmsAliasAttributes.new({
          name: test_case[:name],
          target_key_id: "12345678-1234-1234-1234-123456789012"
        })
        
        expect(attrs.estimated_alias_purpose).to eq(test_case[:expected_purpose])
      end
    end
    
    it "detects key ID vs key ARN usage" do
      # Key ID format
      attrs1 = Pangea::Resources::AWS::Types::KmsAliasAttributes.new({
        name: "alias/test-key-id",
        target_key_id: "12345678-1234-1234-1234-123456789012"
      })
      expect(attrs1.uses_key_id?).to eq(true)
      expect(attrs1.uses_key_arn?).to eq(false)
      
      # Key ARN format
      attrs2 = Pangea::Resources::AWS::Types::KmsAliasAttributes.new({
        name: "alias/test-key-arn",
        target_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      })
      expect(attrs2.uses_key_id?).to eq(false)
      expect(attrs2.uses_key_arn?).to eq(true)
    end
  end
  
  describe "aws_kms_alias function behavior" do
    it "creates an alias with minimal attributes" do
      ref = test_instance.aws_kms_alias(:test_alias, {
        name: "alias/test-key",
        target_key_id: "12345678-1234-1234-1234-123456789012"
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_kms_alias')
      expect(ref.name).to eq(:test_alias)
    end
    
    it "creates an alias pointing to key ID" do
      ref = test_instance.aws_kms_alias(:key_id_alias, {
        name: "alias/app-encryption",
        target_key_id: "12345678-1234-1234-1234-123456789012"
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("alias/app-encryption")
      expect(attrs[:target_key_id]).to eq("12345678-1234-1234-1234-123456789012")
    end
    
    it "creates an alias pointing to key ARN" do
      ref = test_instance.aws_kms_alias(:key_arn_alias, {
        name: "alias/database/prod",
        target_key_id: "arn:aws:kms:us-east-1:123456789012:key/87654321-4321-4321-4321-210987654321"
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("alias/database/prod")
      expect(attrs[:target_key_id]).to eq("arn:aws:kms:us-east-1:123456789012:key/87654321-4321-4321-4321-210987654321")
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_kms_alias(:test_alias, {
        name: "alias/test",
        target_key_id: "12345678-1234-1234-1234-123456789012"
      })
      
      expected_outputs = [:id, :arn, :name, :target_key_arn, :target_key_id]
      
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_kms_alias.test_alias.")
      end
    end
    
    it "provides computed properties" do
      ref = test_instance.aws_kms_alias(:service_alias, {
        name: "alias/rds/production/primary",
        target_key_id: "12345678-1234-1234-1234-123456789012"
      })
      
      expect(ref.alias_suffix).to eq("rds/production/primary")
      expect(ref.is_service_alias?).to eq(true)
      expect(ref.estimated_alias_purpose).to eq("RDS encryption")
      expect(ref.uses_key_id?).to eq(true)
      expect(ref.uses_key_arn?).to eq(false)
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_kms_alias(:test_alias, {
        name: "alias/test",
        target_key_id: "12345678-1234-1234-1234-123456789012"
      })
      
      expect(ref.outputs[:id]).to eq("${aws_kms_alias.test_alias.id}")
      expect(ref.outputs[:arn]).to eq("${aws_kms_alias.test_alias.arn}")
      expect(ref.outputs[:name]).to eq("${aws_kms_alias.test_alias.name}")
      expect(ref.outputs[:target_key_arn]).to eq("${aws_kms_alias.test_alias.target_key_arn}")
      expect(ref.outputs[:target_key_id]).to eq("${aws_kms_alias.test_alias.target_key_id}")
    end
    
    it "can be used with KMS key references" do
      # This would typically use a ResourceReference from aws_kms_key
      key_id = "${aws_kms_key.main.id}"  # Simulated key reference
      
      ref = test_instance.aws_kms_alias(:key_alias, {
        name: "alias/main-key",
        target_key_id: key_id
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:target_key_id]).to eq(key_id)
    end
  end
  
  describe "error conditions and edge cases" do
    it "handles string keys in attributes" do
      ref = test_instance.aws_kms_alias(:string_keys, {
        "name" => "alias/string-test",
        "target_key_id" => "12345678-1234-1234-1234-123456789012"
      })
      
      expect(ref.resource_attributes[:name]).to eq("alias/string-test")
      expect(ref.resource_attributes[:target_key_id]).to eq("12345678-1234-1234-1234-123456789012")
    end
    
    it "validates complex alias naming patterns" do
      complex_names = [
        "alias/app/database/primary",
        "alias/service_encryption",
        "alias/backup-key-2024",
        "alias/multi/level/deep/structure"
      ]
      
      complex_names.each do |name|
        attrs = Pangea::Resources::AWS::Types::KmsAliasAttributes.new({
          name: name,
          target_key_id: "12345678-1234-1234-1234-123456789012"
        })
        expect(attrs.name).to eq(name)
      end
    end
    
    it "validates all supported key ID formats" do
      key_formats = [
        "12345678-1234-1234-1234-123456789012",  # Standard format
        "87654321-4321-4321-4321-210987654321",  # Different values
        "abcdefab-cdef-abcd-efab-cdefabcdefab"   # With hex letters
      ]
      
      key_formats.each do |key_id|
        attrs = Pangea::Resources::AWS::Types::KmsAliasAttributes.new({
          name: "alias/test",
          target_key_id: key_id
        })
        expect(attrs.target_key_id).to eq(key_id)
      end
    end
    
    it "validates all supported key ARN formats" do
      key_arns = [
        "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
        "arn:aws:kms:us-west-2:987654321098:key/87654321-4321-4321-4321-210987654321",
        "arn:aws:kms:eu-west-1:555666777888:key/abcdefab-cdef-abcd-efab-cdefabcdefab"
      ]
      
      key_arns.each do |key_arn|
        attrs = Pangea::Resources::AWS::Types::KmsAliasAttributes.new({
          name: "alias/test",
          target_key_id: key_arn
        })
        expect(attrs.target_key_id).to eq(key_arn)
      end
    end
  end
  
  describe "alias patterns and conventions" do
    it "creates database encryption aliases" do
      ref = test_instance.aws_kms_alias(:db_alias, {
        name: "alias/rds/database/production",
        target_key_id: "12345678-1234-1234-1234-123456789012"
      })
      
      expect(ref.estimated_alias_purpose).to eq("RDS encryption")
      expect(ref.is_service_alias?).to eq(true)
      expect(ref.alias_suffix).to eq("rds/database/production")
    end
    
    it "creates S3 bucket encryption aliases" do
      ref = test_instance.aws_kms_alias(:s3_alias, {
        name: "alias/s3/data-bucket",
        target_key_id: "87654321-4321-4321-4321-210987654321"
      })
      
      expect(ref.estimated_alias_purpose).to eq("S3 bucket encryption")
      expect(ref.is_service_alias?).to eq(true)
    end
    
    it "creates Lambda function encryption aliases" do
      ref = test_instance.aws_kms_alias(:lambda_alias, {
        name: "alias/lambda/api-handler",
        target_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      })
      
      expect(ref.estimated_alias_purpose).to eq("Lambda environment encryption")
      expect(ref.uses_key_arn?).to eq(true)
    end
    
    it "creates Secrets Manager encryption aliases" do
      ref = test_instance.aws_kms_alias(:secrets_alias, {
        name: "alias/secrets/database/password",
        target_key_id: "12345678-1234-1234-1234-123456789012"
      })
      
      expect(ref.estimated_alias_purpose).to eq("Secrets Manager encryption")
    end
    
    it "creates EBS volume encryption aliases" do
      ref = test_instance.aws_kms_alias(:ebs_alias, {
        name: "alias/ebs/default",
        target_key_id: "12345678-1234-1234-1234-123456789012"
      })
      
      expect(ref.estimated_alias_purpose).to eq("EBS volume encryption")
    end
    
    it "creates general purpose aliases" do
      ref = test_instance.aws_kms_alias(:general_alias, {
        name: "alias/general-encryption",
        target_key_id: "12345678-1234-1234-1234-123456789012"
      })
      
      expect(ref.estimated_alias_purpose).to eq("General purpose encryption")
      expect(ref.is_service_alias?).to eq(false)  # No slash in suffix
    end
  end
  
  describe "organizational patterns" do
    it "creates environment-scoped aliases" do
      environments = ['dev', 'staging', 'production']
      
      environments.each_with_index do |env, index|
        ref = test_instance.aws_kms_alias(:"#{env}_alias", {
          name: "alias/app/#{env}",
          target_key_id: "#{index}2345678-1234-1234-1234-123456789012"
        })
        
        expect(ref.alias_suffix).to eq("app/#{env}")
        expect(ref.is_service_alias?).to eq(true)
      end
    end
    
    it "creates service-scoped aliases" do
      services = ['api', 'web', 'worker', 'scheduler']
      
      services.each_with_index do |service, index|
        ref = test_instance.aws_kms_alias(:"#{service}_alias", {
          name: "alias/service/#{service}",
          target_key_id: "#{index}2345678-1234-1234-1234-123456789012"
        })
        
        expect(ref.alias_suffix).to eq("service/#{service}")
        expect(ref.is_service_alias?).to eq(true)
      end
    end
    
    it "creates team-scoped aliases" do
      teams = ['platform', 'backend', 'frontend', 'data']
      
      teams.each_with_index do |team, index|
        ref = test_instance.aws_kms_alias(:"#{team}_alias", {
          name: "alias/team/#{team}",
          target_key_id: "#{index}2345678-1234-1234-1234-123456789012"
        })
        
        expect(ref.alias_suffix).to eq("team/#{team}")
        expect(ref.is_service_alias?).to eq(true)
      end
    end
    
    it "creates multi-level organizational aliases" do
      ref = test_instance.aws_kms_alias(:complex_alias, {
        name: "alias/company/department/team/service/environment",
        target_key_id: "12345678-1234-1234-1234-123456789012"
      })
      
      expect(ref.alias_suffix).to eq("company/department/team/service/environment")
      expect(ref.is_service_alias?).to eq(true)
    end
  end
  
  describe "common KMS alias patterns" do
    it "creates application data encryption alias" do
      ref = test_instance.aws_kms_alias(:app_data, {
        name: "alias/app/data-encryption",
        target_key_id: "12345678-1234-1234-1234-123456789012"
      })
      
      expect(ref.estimated_alias_purpose).to eq("General purpose encryption")
      expect(ref.alias_suffix).to eq("app/data-encryption")
    end
    
    it "creates backup encryption alias" do
      ref = test_instance.aws_kms_alias(:backup_alias, {
        name: "alias/backup/daily",
        target_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      })
      
      expect(ref.alias_suffix).to eq("backup/daily")
      expect(ref.uses_key_arn?).to eq(true)
    end
    
    it "creates cross-account alias" do
      ref = test_instance.aws_kms_alias(:cross_account, {
        name: "alias/shared/cross-account",
        target_key_id: "arn:aws:kms:us-east-1:999888777666:key/12345678-1234-1234-1234-123456789012"
      })
      
      expect(ref.uses_key_arn?).to eq(true)
      expect(ref.alias_suffix).to eq("shared/cross-account")
    end
  end
end