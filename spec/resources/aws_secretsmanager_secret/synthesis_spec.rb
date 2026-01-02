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
require 'pangea/resources/aws_secretsmanager_secret/resource'

RSpec.describe "aws_secretsmanager_secret synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_secretsmanager_secret(:test, {
          name: "test/secret",
          description: "Test secret for synthesis"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_secretsmanager_secret")
      expect(result["resource"]["aws_secretsmanager_secret"]).to have_key("test")

      secret_config = result["resource"]["aws_secretsmanager_secret"]["test"]
      expect(secret_config["name"]).to eq("test/secret")
      expect(secret_config["description"]).to eq("Test secret for synthesis")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_secretsmanager_secret(:test, {
          name: "tagged/secret",
          tags: { Name: "test-secret", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      secret_config = result["resource"]["aws_secretsmanager_secret"]["test"]

      expect(secret_config).to have_key("tags")
      expect(secret_config["tags"]["Name"]).to eq("test-secret")
      expect(secret_config["tags"]["Environment"]).to eq("test")
    end

    it "supports custom KMS key" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_secretsmanager_secret(:test, {
          name: "encrypted/secret",
          kms_key_id: "alias/my-key"
        })
      end

      result = synthesizer.synthesis
      secret_config = result["resource"]["aws_secretsmanager_secret"]["test"]

      expect(secret_config["kms_key_id"]).to eq("alias/my-key")
    end

    it "supports custom recovery window" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_secretsmanager_secret(:test, {
          name: "recoverable/secret",
          recovery_window_in_days: 7
        })
      end

      result = synthesizer.synthesis
      secret_config = result["resource"]["aws_secretsmanager_secret"]["test"]

      expect(secret_config["recovery_window_in_days"]).to eq(7)
    end

    it "supports replica configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_secretsmanager_secret(:test, {
          name: "replicated/secret",
          replica: [
            { region: "us-west-2" },
            { region: "eu-west-1", kms_key_id: "alias/eu-key" }
          ]
        })
      end

      result = synthesizer.synthesis
      secret_config = result["resource"]["aws_secretsmanager_secret"]["test"]

      expect(secret_config).to have_key("replica")
    end

    it "supports force overwrite replica secret" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_secretsmanager_secret(:test, {
          name: "force-replicated/secret",
          force_overwrite_replica_secret: true
        })
      end

      result = synthesizer.synthesis
      secret_config = result["resource"]["aws_secretsmanager_secret"]["test"]

      expect(secret_config["force_overwrite_replica_secret"]).to eq(true)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_secretsmanager_secret(:test, {
          name: "validation/secret"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_secretsmanager_secret"]).to be_a(Hash)
      expect(result["resource"]["aws_secretsmanager_secret"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      secret_config = result["resource"]["aws_secretsmanager_secret"]["test"]
      expect(secret_config).to have_key("name")
      expect(secret_config["name"]).to be_a(String)
    end
  end

  describe "resource references" do
    it "returns a resource reference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_secretsmanager_secret(:test, {
          name: "reference/secret"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq("aws_secretsmanager_secret")
      expect(ref.name).to eq(:test)
      expect(ref.outputs[:id]).to eq("${aws_secretsmanager_secret.test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_secretsmanager_secret.test.arn}")
      expect(ref.outputs[:name]).to eq("${aws_secretsmanager_secret.test.name}")
      expect(ref.outputs[:kms_key_id]).to eq("${aws_secretsmanager_secret.test.kms_key_id}")
    end
  end
end
