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
require 'pangea/resources/aws_secretsmanager_secret_version/resource'

RSpec.describe "aws_secretsmanager_secret_version synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with secret string" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_secretsmanager_secret_version(:test, {
          secret_id: "my-secret",
          secret_string: "supersecretvalue"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_secretsmanager_secret_version")
      expect(result["resource"]["aws_secretsmanager_secret_version"]).to have_key("test")

      version_config = result["resource"]["aws_secretsmanager_secret_version"]["test"]
      expect(version_config["secret_id"]).to eq("my-secret")
      expect(version_config["secret_string"]).to eq("supersecretvalue")
    end

    it "supports JSON secret string" do
      json_secret = { username: "admin", password: "secret123" }
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_secretsmanager_secret_version(:test, {
          secret_id: "db-credentials",
          secret_string: { username: "admin", password: "secret123" }
        })
      end

      result = synthesizer.synthesis
      version_config = result["resource"]["aws_secretsmanager_secret_version"]["test"]

      expect(version_config["secret_string"]).to eq(json_secret.to_json)
    end

    it "supports secret binary" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_secretsmanager_secret_version(:test, {
          secret_id: "binary-secret",
          secret_binary: "YmluYXJ5c2VjcmV0"
        })
      end

      result = synthesizer.synthesis
      version_config = result["resource"]["aws_secretsmanager_secret_version"]["test"]

      expect(version_config["secret_binary"]).to eq("YmluYXJ5c2VjcmV0")
    end

    it "supports version stages" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_secretsmanager_secret_version(:test, {
          secret_id: "staged-secret",
          secret_string: "staged-value",
          version_stages: ["AWSCURRENT", "CUSTOM_STAGE"]
        })
      end

      result = synthesizer.synthesis
      version_config = result["resource"]["aws_secretsmanager_secret_version"]["test"]

      expect(version_config["version_stages"]).to eq(["AWSCURRENT", "CUSTOM_STAGE"])
    end

    it "supports terraform reference as secret_id" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_secretsmanager_secret_version(:test, {
          secret_id: "${aws_secretsmanager_secret.main.id}",
          secret_string: "referenced-value"
        })
      end

      result = synthesizer.synthesis
      version_config = result["resource"]["aws_secretsmanager_secret_version"]["test"]

      expect(version_config["secret_id"]).to eq("${aws_secretsmanager_secret.main.id}")
    end

    it "supports secret ARN as secret_id" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_secretsmanager_secret_version(:test, {
          secret_id: "arn:aws:secretsmanager:us-east-1:123456789012:secret:my-secret-AbCdEf",
          secret_string: "arn-referenced-value"
        })
      end

      result = synthesizer.synthesis
      version_config = result["resource"]["aws_secretsmanager_secret_version"]["test"]

      expect(version_config["secret_id"]).to eq("arn:aws:secretsmanager:us-east-1:123456789012:secret:my-secret-AbCdEf")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_secretsmanager_secret_version(:test, {
          secret_id: "validation-secret",
          secret_string: "validation-value"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_secretsmanager_secret_version"]).to be_a(Hash)
      expect(result["resource"]["aws_secretsmanager_secret_version"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      version_config = result["resource"]["aws_secretsmanager_secret_version"]["test"]
      expect(version_config).to have_key("secret_id")
      expect(version_config["secret_id"]).to be_a(String)
    end
  end

  describe "resource references" do
    it "returns a resource reference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_secretsmanager_secret_version(:test, {
          secret_id: "reference-secret",
          secret_string: "reference-value"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq("aws_secretsmanager_secret_version")
      expect(ref.name).to eq(:test)
      expect(ref.outputs[:id]).to eq("${aws_secretsmanager_secret_version.test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_secretsmanager_secret_version.test.arn}")
      expect(ref.outputs[:secret_id]).to eq("${aws_secretsmanager_secret_version.test.secret_id}")
      expect(ref.outputs[:version_id]).to eq("${aws_secretsmanager_secret_version.test.version_id}")
      expect(ref.outputs[:version_stages]).to eq("${aws_secretsmanager_secret_version.test.version_stages}")
    end
  end
end
