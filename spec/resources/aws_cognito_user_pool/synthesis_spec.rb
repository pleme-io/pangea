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
require 'pangea/resources/aws_cognito_user_pool/resource'

RSpec.describe "aws_cognito_user_pool synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with minimal config" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool(:test, {
          name: "test-pool"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_cognito_user_pool")
      expect(result["resource"]["aws_cognito_user_pool"]).to have_key("test")

      pool_config = result["resource"]["aws_cognito_user_pool"]["test"]
      expect(pool_config["pool_name"]).to eq("test-pool")
    end

    it "includes password policy when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool(:test, {
          name: "test-pool",
          password_policy: {
            minimum_length: 12,
            require_lowercase: true,
            require_uppercase: true,
            require_numbers: true,
            require_symbols: true
          }
        })
      end

      result = synthesizer.synthesis
      pool_config = result["resource"]["aws_cognito_user_pool"]["test"]

      expect(pool_config).to have_key("password_policy")
      expect(pool_config["password_policy"]["minimum_length"]).to eq(12)
      expect(pool_config["password_policy"]["require_lowercase"]).to eq(true)
      expect(pool_config["password_policy"]["require_uppercase"]).to eq(true)
    end

    it "applies MFA configuration correctly" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool(:test, {
          name: "test-pool",
          mfa_configuration: "ON",
          software_token_mfa_configuration: { enabled: true }
        })
      end

      result = synthesizer.synthesis
      pool_config = result["resource"]["aws_cognito_user_pool"]["test"]

      expect(pool_config["mfa_configuration"]).to eq("ON")
      expect(pool_config).to have_key("software_token_mfa_configuration")
      expect(pool_config["software_token_mfa_configuration"]["enabled"]).to eq(true)
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool(:test, {
          name: "test-pool",
          tags: { Name: "test-pool", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      pool_config = result["resource"]["aws_cognito_user_pool"]["test"]

      expect(pool_config).to have_key("tags")
      expect(pool_config["tags"]["Name"]).to eq("test-pool")
      expect(pool_config["tags"]["Environment"]).to eq("test")
    end

    it "supports username attributes configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool(:test, {
          name: "test-pool",
          username_attributes: ["email"],
          auto_verified_attributes: ["email"]
        })
      end

      result = synthesizer.synthesis
      pool_config = result["resource"]["aws_cognito_user_pool"]["test"]

      expect(pool_config["username_attributes"]).to eq(["email"])
      expect(pool_config["auto_verified_attributes"]).to eq(["email"])
    end

    it "configures account recovery settings" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool(:test, {
          name: "test-pool",
          account_recovery_setting: {
            recovery_mechanisms: [
              { name: "verified_email", priority: 1 }
            ]
          }
        })
      end

      result = synthesizer.synthesis
      pool_config = result["resource"]["aws_cognito_user_pool"]["test"]

      expect(pool_config).to have_key("account_recovery_setting")
      expect(pool_config["account_recovery_setting"]).to have_key("recovery_mechanism")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool(:test, { name: "test-pool" })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_cognito_user_pool"]).to be_a(Hash)
      expect(result["resource"]["aws_cognito_user_pool"]["test"]).to be_a(Hash)

      pool_config = result["resource"]["aws_cognito_user_pool"]["test"]
      expect(pool_config).to have_key("pool_name")
      expect(pool_config["pool_name"]).to be_a(String)
    end
  end

  describe "resource reference" do
    it "returns a resource reference with correct outputs" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_user_pool(:test, { name: "test-pool" })
      end

      expect(reference).to be_a(Pangea::Resources::ResourceReference)
      expect(reference.outputs[:id]).to eq("${aws_cognito_user_pool.test.id}")
      expect(reference.outputs[:arn]).to eq("${aws_cognito_user_pool.test.arn}")
      expect(reference.outputs[:endpoint]).to eq("${aws_cognito_user_pool.test.endpoint}")
    end
  end
end
