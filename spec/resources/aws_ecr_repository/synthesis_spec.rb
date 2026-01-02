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
require 'terraform-synthesizer'
require 'pangea/resources/aws_ecr_repository/resource'

RSpec.describe "aws_ecr_repository synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_repository(:test, {
          name: "myapp"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_ecr_repository")
      expect(result["resource"]["aws_ecr_repository"]).to have_key("test")

      repo_config = result["resource"]["aws_ecr_repository"]["test"]
      expect(repo_config["name"]).to eq("myapp")
      expect(repo_config["image_tag_mutability"]).to eq("MUTABLE")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_repository(:test, {
          name: "myapp",
          tags: { Name: "myapp", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      repo_config = result["resource"]["aws_ecr_repository"]["test"]

      expect(repo_config).to have_key("tags")
      expect(repo_config["tags"]["Name"]).to eq("myapp")
      expect(repo_config["tags"]["Environment"]).to eq("test")
    end

    it "supports immutable image tags" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_repository(:test, {
          name: "myapp",
          image_tag_mutability: "IMMUTABLE"
        })
      end

      result = synthesizer.synthesis
      repo_config = result["resource"]["aws_ecr_repository"]["test"]

      expect(repo_config["image_tag_mutability"]).to eq("IMMUTABLE")
    end

    it "supports image scanning configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_repository(:test, {
          name: "myapp",
          image_scanning_configuration: {
            scan_on_push: true
          }
        })
      end

      result = synthesizer.synthesis
      repo_config = result["resource"]["aws_ecr_repository"]["test"]

      expect(repo_config).to have_key("image_scanning_configuration")
      expect(repo_config["image_scanning_configuration"]["scan_on_push"]).to eq(true)
    end

    it "supports KMS encryption configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_repository(:test, {
          name: "myapp",
          encryption_configuration: {
            encryption_type: "KMS",
            kms_key: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
          }
        })
      end

      result = synthesizer.synthesis
      repo_config = result["resource"]["aws_ecr_repository"]["test"]

      expect(repo_config).to have_key("encryption_configuration")
      encryption_config = repo_config["encryption_configuration"]
      expect(encryption_config["encryption_type"]).to eq("KMS")
      expect(encryption_config["kms_key"]).to eq("arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012")
    end

    it "supports AES256 encryption configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_repository(:test, {
          name: "myapp",
          encryption_configuration: {
            encryption_type: "AES256"
          }
        })
      end

      result = synthesizer.synthesis
      repo_config = result["resource"]["aws_ecr_repository"]["test"]

      expect(repo_config).to have_key("encryption_configuration")
      expect(repo_config["encryption_configuration"]["encryption_type"]).to eq("AES256")
    end

    it "supports force delete option" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_repository(:test, {
          name: "myapp-dev",
          force_delete: true
        })
      end

      result = synthesizer.synthesis
      repo_config = result["resource"]["aws_ecr_repository"]["test"]

      expect(repo_config["force_delete"]).to eq(true)
    end

    it "applies default values correctly" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_repository(:test, { name: "myapp" })
      end

      result = synthesizer.synthesis
      repo_config = result["resource"]["aws_ecr_repository"]["test"]

      expect(repo_config["image_tag_mutability"]).to eq("MUTABLE")
      expect(repo_config["force_delete"]).to eq(false)
      expect(repo_config).to have_key("image_scanning_configuration")
    end

    it "supports production-ready configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_repository(:test, {
          name: "production-app",
          image_tag_mutability: "IMMUTABLE",
          image_scanning_configuration: {
            scan_on_push: true
          },
          encryption_configuration: {
            encryption_type: "KMS",
            kms_key: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
          },
          force_delete: false,
          tags: {
            Environment: "production",
            Application: "web",
            ManagedBy: "terraform"
          }
        })
      end

      result = synthesizer.synthesis
      repo_config = result["resource"]["aws_ecr_repository"]["test"]

      expect(repo_config["name"]).to eq("production-app")
      expect(repo_config["image_tag_mutability"]).to eq("IMMUTABLE")
      expect(repo_config["image_scanning_configuration"]["scan_on_push"]).to eq(true)
      expect(repo_config["encryption_configuration"]["encryption_type"]).to eq("KMS")
      expect(repo_config["force_delete"]).to eq(false)
      expect(repo_config["tags"]["Environment"]).to eq("production")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ecr_repository(:test, { name: "myapp" })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_ecr_repository"]).to be_a(Hash)
      expect(result["resource"]["aws_ecr_repository"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      repo_config = result["resource"]["aws_ecr_repository"]["test"]
      expect(repo_config).to have_key("name")
      expect(repo_config["name"]).to be_a(String)
    end
  end

  describe "resource references" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecr_repository(:test, { name: "myapp" })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.arn).to eq("${aws_ecr_repository.test.arn}")
      expect(ref.name).to eq("${aws_ecr_repository.test.name}")
      expect(ref.registry_id).to eq("${aws_ecr_repository.test.registry_id}")
      expect(ref.repository_url).to eq("${aws_ecr_repository.test.repository_url}")
    end

    it "provides computed properties for mutable repository" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecr_repository(:test, {
          name: "myapp",
          image_tag_mutability: "MUTABLE"
        })
      end

      expect(ref.is_immutable?).to eq(false)
      expect(ref.scan_on_push_enabled?).to eq(false)
    end

    it "provides computed properties for immutable repository with scanning" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecr_repository(:test, {
          name: "myapp",
          image_tag_mutability: "IMMUTABLE",
          image_scanning_configuration: {
            scan_on_push: true
          }
        })
      end

      expect(ref.is_immutable?).to eq(true)
      expect(ref.scan_on_push_enabled?).to eq(true)
    end

    it "provides computed properties for KMS encryption" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecr_repository(:test, {
          name: "myapp",
          encryption_configuration: {
            encryption_type: "KMS",
            kms_key: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
          }
        })
      end

      expect(ref.uses_kms_encryption?).to eq(true)
      expect(ref.uses_aes256_encryption?).to eq(false)
    end

    it "provides computed properties for AES256 encryption" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecr_repository(:test, {
          name: "myapp",
          encryption_configuration: {
            encryption_type: "AES256"
          }
        })
      end

      expect(ref.uses_kms_encryption?).to eq(false)
      expect(ref.uses_aes256_encryption?).to eq(true)
    end

    it "provides computed properties for force delete" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ecr_repository(:test, {
          name: "myapp-dev",
          force_delete: true
        })
      end

      expect(ref.allows_force_delete?).to eq(true)
    end
  end
end
