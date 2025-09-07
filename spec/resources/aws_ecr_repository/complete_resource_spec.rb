# frozen_string_literal: true
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

# Load aws_ecr_repository resource and types for testing
require 'pangea/resources/aws_ecr_repository/resource'
require 'pangea/resources/aws_ecr_repository/types'

RSpec.describe "aws_ecr_repository resource function" do
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
  let(:kms_key_arn) { "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" }
  
  describe "ECRRepositoryAttributes validation" do
    it "accepts basic repository configuration" do
      attrs = Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
        name: "myapp",
        image_tag_mutability: "MUTABLE"
      })
      
      expect(attrs.name).to eq("myapp")
      expect(attrs.image_tag_mutability).to eq("MUTABLE")
      expect(attrs.force_delete).to eq(false)
      expect(attrs.scan_on_push_enabled?).to eq(false)
      expect(attrs.is_immutable?).to eq(false)
    end
    
    it "accepts immutable repository configuration" do
      attrs = Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
        name: "secure-app",
        image_tag_mutability: "IMMUTABLE",
        image_scanning_configuration: {
          scan_on_push: true
        }
      })
      
      expect(attrs.name).to eq("secure-app")
      expect(attrs.image_tag_mutability).to eq("IMMUTABLE")
      expect(attrs.is_immutable?).to eq(true)
      expect(attrs.scan_on_push_enabled?).to eq(true)
    end
    
    it "accepts AES256 encryption configuration" do
      attrs = Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
        name: "encrypted-repo",
        encryption_configuration: {
          encryption_type: "AES256"
        }
      })
      
      expect(attrs.name).to eq("encrypted-repo")
      expect(attrs.uses_aes256_encryption?).to eq(true)
      expect(attrs.uses_kms_encryption?).to eq(false)
    end
    
    it "accepts KMS encryption configuration" do
      attrs = Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
        name: "kms-repo",
        encryption_configuration: {
          encryption_type: "KMS",
          kms_key: kms_key_arn
        }
      })
      
      expect(attrs.name).to eq("kms-repo")
      expect(attrs.uses_kms_encryption?).to eq(true)
      expect(attrs.uses_aes256_encryption?).to eq(false)
    end
    
    it "accepts force delete configuration" do
      attrs = Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
        name: "dev-repo",
        force_delete: true
      })
      
      expect(attrs.name).to eq("dev-repo")
      expect(attrs.allows_force_delete?).to eq(true)
    end
    
    it "accepts complex repository configuration" do
      attrs = Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
        name: "production-app",
        image_tag_mutability: "IMMUTABLE",
        image_scanning_configuration: {
          scan_on_push: true
        },
        encryption_configuration: {
          encryption_type: "KMS",
          kms_key: kms_key_arn
        },
        force_delete: false,
        tags: {
          Environment: "production",
          Application: "web-app",
          Team: "backend"
        }
      })
      
      expect(attrs.name).to eq("production-app")
      expect(attrs.image_tag_mutability).to eq("IMMUTABLE")
      expect(attrs.is_immutable?).to eq(true)
      expect(attrs.scan_on_push_enabled?).to eq(true)
      expect(attrs.uses_kms_encryption?).to eq(true)
      expect(attrs.allows_force_delete?).to eq(false)
      expect(attrs.tags[:Environment]).to eq("production")
      expect(attrs.tags[:Application]).to eq("web-app")
      expect(attrs.tags[:Team]).to eq("backend")
    end
  end
  
  describe "repository name validation" do
    it "accepts valid lowercase names" do
      valid_names = [
        "myapp",
        "my-app",
        "my_app",
        "my.app",
        "app123",
        "123app",
        "my-app.service",
        "microservice-v2"
      ]
      
      valid_names.each do |name|
        expect {
          Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
            name: name
          })
        }.not_to raise_error
      end
    end
    
    it "rejects names with uppercase letters" do
      expect {
        Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
          name: "MyApp"
        })
      }.to raise_error(Dry::Struct::Error, /must contain only lowercase/)
    end
    
    it "rejects names with invalid characters" do
      invalid_names = [
        "my@app",
        "my app",
        "my#app",
        "my&app"
      ]
      
      invalid_names.each do |name|
        expect {
          Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
            name: name
          })
        }.to raise_error(Dry::Struct::Error, /must contain only lowercase/)
      end
    end
    
    it "rejects names starting or ending with hyphens" do
      expect {
        Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
          name: "-myapp"
        })
      }.to raise_error(Dry::Struct::Error, /cannot start or end with hyphens/)
      
      expect {
        Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
          name: "myapp-"
        })
      }.to raise_error(Dry::Struct::Error, /cannot start or end with hyphens/)
    end
    
    it "rejects names that are too short" do
      expect {
        Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
          name: "a"
        })
      }.to raise_error(Dry::Struct::Error, /must be between 2 and 256 characters/)
    end
    
    it "rejects names that are too long" do
      long_name = "a" * 257
      expect {
        Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
          name: long_name
        })
      }.to raise_error(Dry::Struct::Error, /must be between 2 and 256 characters/)
    end
  end
  
  describe "encryption configuration validation" do
    it "requires KMS key when encryption type is KMS" do
      expect {
        Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
          name: "test-repo",
          encryption_configuration: {
            encryption_type: "KMS"
          }
        })
      }.to raise_error(Dry::Struct::Error, /kms_key is required when encryption_type is KMS/)
    end
    
    it "rejects KMS key when encryption type is not KMS" do
      expect {
        Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
          name: "test-repo",
          encryption_configuration: {
            encryption_type: "AES256",
            kms_key: kms_key_arn
          }
        })
      }.to raise_error(Dry::Struct::Error, /kms_key can only be specified when encryption_type is KMS/)
    end
    
    it "accepts KMS configuration with valid key" do
      expect {
        Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
          name: "test-repo",
          encryption_configuration: {
            encryption_type: "KMS",
            kms_key: kms_key_arn
          }
        })
      }.not_to raise_error
    end
  end
  
  describe "image tag mutability validation" do
    it "accepts MUTABLE mutability" do
      attrs = Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
        name: "test-repo",
        image_tag_mutability: "MUTABLE"
      })
      
      expect(attrs.image_tag_mutability).to eq("MUTABLE")
      expect(attrs.is_immutable?).to eq(false)
    end
    
    it "accepts IMMUTABLE mutability" do
      attrs = Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
        name: "test-repo",
        image_tag_mutability: "IMMUTABLE"
      })
      
      expect(attrs.image_tag_mutability).to eq("IMMUTABLE")
      expect(attrs.is_immutable?).to eq(true)
    end
    
    it "rejects invalid mutability values" do
      expect {
        Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
          name: "test-repo",
          image_tag_mutability: "INVALID"
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end
  
  describe "computed properties" do
    let(:attrs) do
      Pangea::Resources::AWS::Types::ECRRepositoryAttributes.new({
        name: "test-repo",
        image_tag_mutability: "IMMUTABLE",
        image_scanning_configuration: {
          scan_on_push: true
        },
        encryption_configuration: {
          encryption_type: "KMS",
          kms_key: kms_key_arn
        },
        force_delete: true
      })
    end
    
    it "provides repository URI template" do
      expect(attrs.repository_uri_template).to eq("${aws_ecr_repository.%{name}.repository_url}")
    end
    
    it "provides registry ID template" do
      expect(attrs.registry_id_template).to eq("${aws_ecr_repository.%{name}.registry_id}")
    end
    
    it "detects immutable configuration" do
      expect(attrs.is_immutable?).to eq(true)
    end
    
    it "detects scan on push configuration" do
      expect(attrs.scan_on_push_enabled?).to eq(true)
    end
    
    it "detects KMS encryption" do
      expect(attrs.uses_kms_encryption?).to eq(true)
      expect(attrs.uses_aes256_encryption?).to eq(false)
    end
    
    it "detects force delete configuration" do
      expect(attrs.allows_force_delete?).to eq(true)
    end
  end
  
  describe "aws_ecr_repository function" do
    it "creates basic ECR repository" do
      result = test_instance.aws_ecr_repository(:myapp, {
        name: "myapp"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_ecr_repository')
      expect(result.name).to eq(:myapp)
    end
    
    it "creates repository with scanning enabled" do
      result = test_instance.aws_ecr_repository(:scanned_app, {
        name: "scanned-app",
        image_scanning_configuration: {
          scan_on_push: true
        }
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.scan_on_push_enabled?).to eq(true)
    end
    
    it "creates immutable repository" do
      result = test_instance.aws_ecr_repository(:immutable_app, {
        name: "immutable-app",
        image_tag_mutability: "IMMUTABLE"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.is_immutable?).to eq(true)
    end
    
    it "creates repository with KMS encryption" do
      result = test_instance.aws_ecr_repository(:encrypted_app, {
        name: "encrypted-app",
        encryption_configuration: {
          encryption_type: "KMS",
          kms_key: kms_key_arn
        }
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.uses_kms_encryption?).to eq(true)
    end
    
    it "creates repository with force delete" do
      result = test_instance.aws_ecr_repository(:dev_app, {
        name: "dev-app",
        force_delete: true
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.allows_force_delete?).to eq(true)
    end
    
    it "provides correct outputs" do
      result = test_instance.aws_ecr_repository(:myapp, {
        name: "myapp"
      })
      
      expect(result.arn).to eq("${aws_ecr_repository.myapp.arn}")
      expect(result.name).to eq("${aws_ecr_repository.myapp.name}")
      expect(result.registry_id).to eq("${aws_ecr_repository.myapp.registry_id}")
      expect(result.repository_url).to eq("${aws_ecr_repository.myapp.repository_url}")
      expect(result.tags_all).to eq("${aws_ecr_repository.myapp.tags_all}")
    end
    
    it "provides computed properties" do
      result = test_instance.aws_ecr_repository(:myapp, {
        name: "myapp",
        image_tag_mutability: "IMMUTABLE",
        image_scanning_configuration: {
          scan_on_push: true
        },
        encryption_configuration: {
          encryption_type: "KMS",
          kms_key: kms_key_arn
        }
      })
      
      expect(result.repository_uri_template).to eq("${aws_ecr_repository.%{name}.repository_url}")
      expect(result.registry_id_template).to eq("${aws_ecr_repository.%{name}.registry_id}")
      expect(result.is_immutable?).to eq(true)
      expect(result.scan_on_push_enabled?).to eq(true)
      expect(result.uses_kms_encryption?).to eq(true)
      expect(result.uses_aes256_encryption?).to eq(false)
    end
  end
  
  describe "microservices repository patterns" do
    it "creates repositories for microservices architecture" do
      services = [
        { name: :user_service, repo_name: "user-service" },
        { name: :order_service, repo_name: "order-service" },
        { name: :payment_service, repo_name: "payment-service" },
        { name: :notification_service, repo_name: "notification-service" }
      ]
      
      repositories = services.map do |service|
        test_instance.aws_ecr_repository(service[:name], {
          name: service[:repo_name],
          image_tag_mutability: "IMMUTABLE",
          image_scanning_configuration: {
            scan_on_push: true
          },
          tags: {
            Environment: "production",
            Service: service[:repo_name],
            Architecture: "microservices"
          }
        })
      end
      
      repositories.each do |repo|
        expect(repo).to be_a(Pangea::Resources::ResourceReference)
        expect(repo.is_immutable?).to eq(true)
        expect(repo.scan_on_push_enabled?).to eq(true)
      end
    end
  end
  
  describe "multi-environment repository patterns" do
    it "creates environment-specific repositories" do
      environments = [
        { env: "development", force_delete: true, mutability: "MUTABLE", scanning: false },
        { env: "staging", force_delete: false, mutability: "MUTABLE", scanning: true },
        { env: "production", force_delete: false, mutability: "IMMUTABLE", scanning: true }
      ]
      
      repositories = environments.map do |env|
        test_instance.aws_ecr_repository(:"myapp_#{env[:env]}", {
          name: "myapp-#{env[:env]}",
          image_tag_mutability: env[:mutability],
          image_scanning_configuration: {
            scan_on_push: env[:scanning]
          },
          force_delete: env[:force_delete],
          tags: {
            Environment: env[:env],
            Application: "myapp"
          }
        })
      end
      
      dev_repo = repositories[0]
      staging_repo = repositories[1]
      prod_repo = repositories[2]
      
      expect(dev_repo.allows_force_delete?).to eq(true)
      expect(dev_repo.is_immutable?).to eq(false)
      expect(dev_repo.scan_on_push_enabled?).to eq(false)
      
      expect(staging_repo.allows_force_delete?).to eq(false)
      expect(staging_repo.is_immutable?).to eq(false)
      expect(staging_repo.scan_on_push_enabled?).to eq(true)
      
      expect(prod_repo.allows_force_delete?).to eq(false)
      expect(prod_repo.is_immutable?).to eq(true)
      expect(prod_repo.scan_on_push_enabled?).to eq(true)
    end
  end
  
  describe "security-focused repository patterns" do
    it "creates high-security repository" do
      result = test_instance.aws_ecr_repository(:secure_app, {
        name: "secure-application",
        image_tag_mutability: "IMMUTABLE",
        image_scanning_configuration: {
          scan_on_push: true
        },
        encryption_configuration: {
          encryption_type: "KMS",
          kms_key: kms_key_arn
        },
        force_delete: false,
        tags: {
          Environment: "production",
          Security: "high",
          Compliance: "required",
          DataClassification: "confidential"
        }
      })
      
      expect(result.is_immutable?).to eq(true)
      expect(result.scan_on_push_enabled?).to eq(true)
      expect(result.uses_kms_encryption?).to eq(true)
      expect(result.allows_force_delete?).to eq(false)
    end
    
    it "creates development repository with relaxed security" do
      result = test_instance.aws_ecr_repository(:dev_app, {
        name: "dev-application",
        image_tag_mutability: "MUTABLE",
        image_scanning_configuration: {
          scan_on_push: false
        },
        encryption_configuration: {
          encryption_type: "AES256"
        },
        force_delete: true,
        tags: {
          Environment: "development",
          Security: "standard"
        }
      })
      
      expect(result.is_immutable?).to eq(false)
      expect(result.scan_on_push_enabled?).to eq(false)
      expect(result.uses_aes256_encryption?).to eq(true)
      expect(result.allows_force_delete?).to eq(true)
    end
  end
  
  describe "container CI/CD patterns" do
    it "creates repositories for CI/CD pipeline" do
      pipeline_repos = [
        { name: :base_images, repo_name: "base-images", role: "base" },
        { name: :build_images, repo_name: "build-images", role: "build" },
        { name: :runtime_images, repo_name: "runtime-images", role: "runtime" }
      ]
      
      repositories = pipeline_repos.map do |repo_config|
        test_instance.aws_ecr_repository(repo_config[:name], {
          name: repo_config[:repo_name],
          image_tag_mutability: "MUTABLE",
          image_scanning_configuration: {
            scan_on_push: true
          },
          tags: {
            Environment: "cicd",
            Role: repo_config[:role],
            Purpose: "container-pipeline"
          }
        })
      end
      
      repositories.each do |repo|
        expect(repo.scan_on_push_enabled?).to eq(true)
        expect(repo.is_immutable?).to eq(false) # Allow overwriting for CI/CD
      end
    end
  end
end