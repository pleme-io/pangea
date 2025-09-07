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
require 'json'

# Load aws_ecr_repository resource and terraform-synthesizer for testing
require 'pangea/resources/aws_ecr_repository/resource'
require 'terraform-synthesizer'

RSpec.describe "aws_ecr_repository terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  let(:kms_key_arn) { "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" }

  # Test basic repository synthesis
  it "synthesizes basic ECR repository correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecr_repository(:myapp, {
        name: "myapp",
        image_tag_mutability: "MUTABLE"
      })
    end
    
    json_output = synthesizer.synthesis
    repo_config = json_output.dig(:resource, :aws_ecr_repository, :myapp)
    
    expect(repo_config[:name]).to eq("myapp")
    expect(repo_config[:image_tag_mutability]).to eq("MUTABLE")
    expect(repo_config[:force_delete]).to eq(false)
    expect(repo_config[:image_scanning_configuration]).to be_a(Hash)
    expect(repo_config[:image_scanning_configuration][:scan_on_push]).to eq(false)
  end

  # Test immutable repository synthesis
  it "synthesizes immutable repository correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecr_repository(:immutable_app, {
        name: "immutable-app",
        image_tag_mutability: "IMMUTABLE",
        image_scanning_configuration: {
          scan_on_push: true
        }
      })
    end
    
    json_output = synthesizer.synthesis
    repo_config = json_output.dig(:resource, :aws_ecr_repository, :immutable_app)
    
    expect(repo_config[:name]).to eq("immutable-app")
    expect(repo_config[:image_tag_mutability]).to eq("IMMUTABLE")
    expect(repo_config[:image_scanning_configuration][:scan_on_push]).to eq(true)
  end

  # Test repository with KMS encryption synthesis
  it "synthesizes repository with KMS encryption correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecr_repository(:encrypted_app, {
        name: "encrypted-app",
        encryption_configuration: {
          encryption_type: "KMS",
          kms_key: kms_key_arn
        }
      })
    end
    
    json_output = synthesizer.synthesis
    repo_config = json_output.dig(:resource, :aws_ecr_repository, :encrypted_app)
    
    expect(repo_config[:name]).to eq("encrypted-app")
    expect(repo_config[:encryption_configuration]).to be_an(Array)
    
    encryption_config = repo_config[:encryption_configuration][0]
    expect(encryption_config[:encryption_type]).to eq("KMS")
    expect(encryption_config[:kms_key]).to eq(kms_key_arn)
  end

  # Test repository with AES256 encryption synthesis
  it "synthesizes repository with AES256 encryption correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecr_repository(:aes_app, {
        name: "aes-app",
        encryption_configuration: {
          encryption_type: "AES256"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    repo_config = json_output.dig(:resource, :aws_ecr_repository, :aes_app)
    
    expect(repo_config[:name]).to eq("aes-app")
    expect(repo_config[:encryption_configuration]).to be_an(Array)
    
    encryption_config = repo_config[:encryption_configuration][0]
    expect(encryption_config[:encryption_type]).to eq("AES256")
    expect(encryption_config).not_to have_key(:kms_key)
  end

  # Test repository with force delete synthesis
  it "synthesizes repository with force delete correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecr_repository(:dev_app, {
        name: "dev-app",
        force_delete: true
      })
    end
    
    json_output = synthesizer.synthesis
    repo_config = json_output.dig(:resource, :aws_ecr_repository, :dev_app)
    
    expect(repo_config[:name]).to eq("dev-app")
    expect(repo_config[:force_delete]).to eq(true)
  end

  # Test repository with comprehensive configuration synthesis
  it "synthesizes comprehensive repository configuration correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecr_repository(:comprehensive, {
        name: "comprehensive-app",
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
          Team: "backend",
          Security: "high"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    repo_config = json_output.dig(:resource, :aws_ecr_repository, :comprehensive)
    
    expect(repo_config[:name]).to eq("comprehensive-app")
    expect(repo_config[:image_tag_mutability]).to eq("IMMUTABLE")
    expect(repo_config[:image_scanning_configuration][:scan_on_push]).to eq(true)
    expect(repo_config[:force_delete]).to eq(false)
    
    encryption_config = repo_config[:encryption_configuration][0]
    expect(encryption_config[:encryption_type]).to eq("KMS")
    expect(encryption_config[:kms_key]).to eq(kms_key_arn)
    
    expect(repo_config[:tags]).to eq({
      Environment: "production",
      Application: "web-app",
      Team: "backend",
      Security: "high"
    })
  end

  # Test microservices repositories synthesis
  it "synthesizes microservices repositories correctly" do
    services = [
      { name: :user_service, repo_name: "user-service" },
      { name: :order_service, repo_name: "order-service" },
      { name: :payment_service, repo_name: "payment-service" }
    ]
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      services.each do |service|
        aws_ecr_repository(service[:name], {
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
    end
    
    json_output = synthesizer.synthesis
    
    services.each do |service|
      repo_config = json_output.dig(:resource, :aws_ecr_repository, service[:name])
      
      expect(repo_config[:name]).to eq(service[:repo_name])
      expect(repo_config[:image_tag_mutability]).to eq("IMMUTABLE")
      expect(repo_config[:image_scanning_configuration][:scan_on_push]).to eq(true)
      expect(repo_config[:tags][:Service]).to eq(service[:repo_name])
      expect(repo_config[:tags][:Architecture]).to eq("microservices")
    end
  end

  # Test multi-environment repositories synthesis
  it "synthesizes multi-environment repositories correctly" do
    environments = [
      { env: "development", force_delete: true, mutability: "MUTABLE", scanning: false },
      { env: "staging", force_delete: false, mutability: "MUTABLE", scanning: true },
      { env: "production", force_delete: false, mutability: "IMMUTABLE", scanning: true }
    ]
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      environments.each do |env|
        aws_ecr_repository(:"myapp_#{env[:env]}", {
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
    end
    
    json_output = synthesizer.synthesis
    
    environments.each do |env|
      repo_name = :"myapp_#{env[:env]}"
      repo_config = json_output.dig(:resource, :aws_ecr_repository, repo_name)
      
      expect(repo_config[:name]).to eq("myapp-#{env[:env]}")
      expect(repo_config[:image_tag_mutability]).to eq(env[:mutability])
      expect(repo_config[:image_scanning_configuration][:scan_on_push]).to eq(env[:scanning])
      expect(repo_config[:force_delete]).to eq(env[:force_delete])
      expect(repo_config[:tags][:Environment]).to eq(env[:env])
    end
  end

  # Test CI/CD pipeline repositories synthesis
  it "synthesizes CI/CD pipeline repositories correctly" do
    pipeline_repos = [
      { name: :base_images, repo_name: "base-images", role: "base" },
      { name: :build_images, repo_name: "build-images", role: "build" },
      { name: :runtime_images, repo_name: "runtime-images", role: "runtime" }
    ]
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      pipeline_repos.each do |repo_config|
        aws_ecr_repository(repo_config[:name], {
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
    end
    
    json_output = synthesizer.synthesis
    
    pipeline_repos.each do |repo_config|
      repo_tf_config = json_output.dig(:resource, :aws_ecr_repository, repo_config[:name])
      
      expect(repo_tf_config[:name]).to eq(repo_config[:repo_name])
      expect(repo_tf_config[:image_tag_mutability]).to eq("MUTABLE")
      expect(repo_tf_config[:image_scanning_configuration][:scan_on_push]).to eq(true)
      expect(repo_tf_config[:tags][:Role]).to eq(repo_config[:role])
      expect(repo_tf_config[:tags][:Purpose]).to eq("container-pipeline")
    end
  end

  # Test security-focused repository synthesis
  it "synthesizes high-security repository correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecr_repository(:secure_app, {
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
    end
    
    json_output = synthesizer.synthesis
    repo_config = json_output.dig(:resource, :aws_ecr_repository, :secure_app)
    
    expect(repo_config[:name]).to eq("secure-application")
    expect(repo_config[:image_tag_mutability]).to eq("IMMUTABLE")
    expect(repo_config[:image_scanning_configuration][:scan_on_push]).to eq(true)
    expect(repo_config[:force_delete]).to eq(false)
    
    encryption_config = repo_config[:encryption_configuration][0]
    expect(encryption_config[:encryption_type]).to eq("KMS")
    expect(encryption_config[:kms_key]).to eq(kms_key_arn)
    
    expect(repo_config[:tags][:Security]).to eq("high")
    expect(repo_config[:tags][:Compliance]).to eq("required")
    expect(repo_config[:tags][:DataClassification]).to eq("confidential")
  end

  # Test container registry pattern synthesis
  it "synthesizes container registry pattern correctly" do
    registry_config = [
      { type: "frontend", apps: ["web-ui", "admin-ui"] },
      { type: "backend", apps: ["api-server", "worker"] },
      { type: "shared", apps: ["nginx", "redis"] }
    ]
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      registry_config.each do |tier|
        tier[:apps].each do |app|
          aws_ecr_repository(:"#{tier[:type]}_#{app.gsub('-', '_')}", {
            name: "#{tier[:type]}-#{app}",
            image_tag_mutability: tier[:type] == "shared" ? "MUTABLE" : "IMMUTABLE",
            image_scanning_configuration: {
              scan_on_push: true
            },
            encryption_configuration: {
              encryption_type: tier[:type] == "shared" ? "AES256" : "KMS",
              kms_key: tier[:type] == "shared" ? nil : kms_key_arn
            }.compact,
            tags: {
              Environment: "production",
              Tier: tier[:type],
              Application: app
            }
          })
        end
      end
    end
    
    json_output = synthesizer.synthesis
    
    # Test frontend repositories
    frontend_web_config = json_output.dig(:resource, :aws_ecr_repository, :frontend_web_ui)
    expect(frontend_web_config[:name]).to eq("frontend-web-ui")
    expect(frontend_web_config[:image_tag_mutability]).to eq("IMMUTABLE")
    expect(frontend_web_config[:encryption_configuration][0][:encryption_type]).to eq("KMS")
    
    # Test shared repositories
    shared_nginx_config = json_output.dig(:resource, :aws_ecr_repository, :shared_nginx)
    expect(shared_nginx_config[:name]).to eq("shared-nginx")
    expect(shared_nginx_config[:image_tag_mutability]).to eq("MUTABLE")
    expect(shared_nginx_config[:encryption_configuration][0][:encryption_type]).to eq("AES256")
  end

  # Test repository naming patterns synthesis
  it "synthesizes repositories with various naming patterns correctly" do
    naming_patterns = [
      { name: "simple-app", expected: "simple-app" },
      { name: "my.service", expected: "my.service" },
      { name: "app_v2", expected: "app_v2" },
      { name: "microservice-backend.api", expected: "microservice-backend.api" },
      { name: "company.team.service", expected: "company.team.service" }
    ]
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      naming_patterns.each_with_index do |pattern, index|
        aws_ecr_repository(:"repo_#{index}", {
          name: pattern[:name]
        })
      end
    end
    
    json_output = synthesizer.synthesis
    
    naming_patterns.each_with_index do |pattern, index|
      repo_config = json_output.dig(:resource, :aws_ecr_repository, :"repo_#{index}")
      expect(repo_config[:name]).to eq(pattern[:expected])
    end
  end

  # Test repository without optional configurations synthesis
  it "synthesizes minimal repository configuration correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecr_repository(:minimal, {
        name: "minimal-repo"
      })
    end
    
    json_output = synthesizer.synthesis
    repo_config = json_output.dig(:resource, :aws_ecr_repository, :minimal)
    
    expect(repo_config[:name]).to eq("minimal-repo")
    expect(repo_config[:image_tag_mutability]).to eq("MUTABLE") # Default
    expect(repo_config[:force_delete]).to eq(false) # Default
    expect(repo_config[:image_scanning_configuration][:scan_on_push]).to eq(false) # Default
    
    # Optional fields should not be present when not specified
    expect(repo_config).not_to have_key(:encryption_configuration)
    expect(repo_config).not_to have_key(:tags)
  end

  # Test repository with all tag types synthesis
  it "synthesizes repository with comprehensive tags correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecr_repository(:tagged_app, {
        name: "tagged-app",
        tags: {
          Environment: "production",
          Application: "web-service",
          Team: "backend-team",
          CostCenter: "engineering",
          Project: "main-platform",
          Owner: "platform-team",
          Backup: "required",
          Monitoring: "enabled",
          Security: "high",
          Compliance: "soc2"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    repo_config = json_output.dig(:resource, :aws_ecr_repository, :tagged_app)
    
    expected_tags = {
      Environment: "production",
      Application: "web-service",
      Team: "backend-team",
      CostCenter: "engineering",
      Project: "main-platform",
      Owner: "platform-team",
      Backup: "required",
      Monitoring: "enabled",
      Security: "high",
      Compliance: "soc2"
    }
    
    expect(repo_config[:tags]).to eq(expected_tags)
  end
end