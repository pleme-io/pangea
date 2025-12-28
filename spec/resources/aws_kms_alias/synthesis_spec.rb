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
require 'pangea/resources/aws_kms_alias/resource'

RSpec.describe "aws_kms_alias synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kms_alias(:test, {
          name: "alias/test-key",
          target_key_id: "12345678-1234-1234-1234-123456789012"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_kms_alias")
      expect(result["resource"]["aws_kms_alias"]).to have_key("test")

      alias_config = result["resource"]["aws_kms_alias"]["test"]
      expect(alias_config["name"]).to eq("alias/test-key")
      expect(alias_config["target_key_id"]).to eq("12345678-1234-1234-1234-123456789012")
    end

    it "supports hierarchical alias names" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kms_alias(:test, {
          name: "alias/myapp/production/database",
          target_key_id: "12345678-1234-1234-1234-123456789012"
        })
      end

      result = synthesizer.synthesis
      alias_config = result["resource"]["aws_kms_alias"]["test"]

      expect(alias_config["name"]).to eq("alias/myapp/production/database")
    end

    it "supports key ARN as target" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kms_alias(:test, {
          name: "alias/arn-target",
          target_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
        })
      end

      result = synthesizer.synthesis
      alias_config = result["resource"]["aws_kms_alias"]["test"]

      expect(alias_config["target_key_id"]).to eq("arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012")
    end

    it "supports terraform reference as target" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kms_alias(:test, {
          name: "alias/ref-target",
          target_key_id: "${aws_kms_key.main.id}"
        })
      end

      result = synthesizer.synthesis
      alias_config = result["resource"]["aws_kms_alias"]["test"]

      expect(alias_config["target_key_id"]).to eq("${aws_kms_key.main.id}")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kms_alias(:test, {
          name: "alias/validation-test",
          target_key_id: "12345678-1234-1234-1234-123456789012"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_kms_alias"]).to be_a(Hash)
      expect(result["resource"]["aws_kms_alias"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      alias_config = result["resource"]["aws_kms_alias"]["test"]
      expect(alias_config).to have_key("name")
      expect(alias_config).to have_key("target_key_id")
      expect(alias_config["name"]).to be_a(String)
      expect(alias_config["target_key_id"]).to be_a(String)
    end
  end

  describe "resource references" do
    it "returns a resource reference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_kms_alias(:test, {
          name: "alias/reference-test",
          target_key_id: "12345678-1234-1234-1234-123456789012"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq("aws_kms_alias")
      expect(ref.name).to eq(:test)
      expect(ref.outputs[:id]).to eq("${aws_kms_alias.test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_kms_alias.test.arn}")
      expect(ref.outputs[:name]).to eq("${aws_kms_alias.test.name}")
      expect(ref.outputs[:target_key_id]).to eq("${aws_kms_alias.test.target_key_id}")
      expect(ref.outputs[:target_key_arn]).to eq("${aws_kms_alias.test.target_key_arn}")
    end
  end
end
