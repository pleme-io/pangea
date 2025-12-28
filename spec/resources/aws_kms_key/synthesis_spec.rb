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
require 'pangea/resources/aws_kms_key/resource'

RSpec.describe "aws_kms_key synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kms_key(:test, {
          description: "Test KMS key for encryption"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_kms_key")
      expect(result["resource"]["aws_kms_key"]).to have_key("test")

      key_config = result["resource"]["aws_kms_key"]["test"]
      expect(key_config["description"]).to eq("Test KMS key for encryption")
      expect(key_config["key_usage"]).to eq("ENCRYPT_DECRYPT")
      expect(key_config["key_spec"]).to eq("SYMMETRIC_DEFAULT")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kms_key(:test, {
          description: "Tagged KMS key",
          tags: { Name: "test-key", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      key_config = result["resource"]["aws_kms_key"]["test"]

      expect(key_config).to have_key("tags")
      expect(key_config["tags"]["Name"]).to eq("test-key")
      expect(key_config["tags"]["Environment"]).to eq("test")
    end

    it "applies default values correctly" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kms_key(:test, { description: "Default test key" })
      end

      result = synthesizer.synthesis
      key_config = result["resource"]["aws_kms_key"]["test"]

      expect(key_config["description"]).to eq("Default test key")
      expect(key_config["key_usage"]).to eq("ENCRYPT_DECRYPT")
      expect(key_config["key_spec"]).to eq("SYMMETRIC_DEFAULT")
    end

    it "supports key rotation for symmetric keys" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kms_key(:test, {
          description: "Rotating encryption key",
          key_spec: "SYMMETRIC_DEFAULT",
          enable_key_rotation: true
        })
      end

      result = synthesizer.synthesis
      key_config = result["resource"]["aws_kms_key"]["test"]

      expect(key_config["enable_key_rotation"]).to eq(true)
    end

    it "supports asymmetric signing keys" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kms_key(:test, {
          description: "RSA signing key",
          key_usage: "SIGN_VERIFY",
          key_spec: "RSA_2048"
        })
      end

      result = synthesizer.synthesis
      key_config = result["resource"]["aws_kms_key"]["test"]

      expect(key_config["key_usage"]).to eq("SIGN_VERIFY")
      expect(key_config["key_spec"]).to eq("RSA_2048")
    end

    it "supports multi-region keys" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kms_key(:test, {
          description: "Multi-region key",
          multi_region: true
        })
      end

      result = synthesizer.synthesis
      key_config = result["resource"]["aws_kms_key"]["test"]

      expect(key_config["multi_region"]).to eq(true)
    end

    it "supports custom deletion window" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kms_key(:test, {
          description: "Key with custom deletion window",
          deletion_window_in_days: 30
        })
      end

      result = synthesizer.synthesis
      key_config = result["resource"]["aws_kms_key"]["test"]

      expect(key_config["deletion_window_in_days"]).to eq(30)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kms_key(:test, { description: "Validation test key" })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_kms_key"]).to be_a(Hash)
      expect(result["resource"]["aws_kms_key"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      key_config = result["resource"]["aws_kms_key"]["test"]
      expect(key_config).to have_key("description")
      expect(key_config["description"]).to be_a(String)
    end
  end

  describe "resource references" do
    it "returns a resource reference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_kms_key(:test, { description: "Reference test key" })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq("aws_kms_key")
      expect(ref.name).to eq(:test)
      expect(ref.outputs[:id]).to eq("${aws_kms_key.test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_kms_key.test.arn}")
      expect(ref.outputs[:key_id]).to eq("${aws_kms_key.test.key_id}")
    end
  end
end
