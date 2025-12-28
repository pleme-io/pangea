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
require 'pangea/resources/aws_cognito_identity_pool/resource'

RSpec.describe "aws_cognito_identity_pool synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with minimal config" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_identity_pool(:test, {
          identity_pool_name: "test-identity-pool",
          allow_unauthenticated_identities: true
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_cognito_identity_pool")
      expect(result["resource"]["aws_cognito_identity_pool"]).to have_key("test")

      pool_config = result["resource"]["aws_cognito_identity_pool"]["test"]
      expect(pool_config["identity_pool_name"]).to eq("test-identity-pool")
      expect(pool_config["allow_unauthenticated_identities"]).to eq(true)
    end

    it "configures Cognito identity providers" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_identity_pool(:test, {
          identity_pool_name: "test-identity-pool",
          cognito_identity_providers: [
            {
              client_id: "client-id-123",
              provider_name: "cognito-idp.us-east-1.amazonaws.com/us-east-1_abc123",
              server_side_token_check: true
            }
          ]
        })
      end

      result = synthesizer.synthesis
      pool_config = result["resource"]["aws_cognito_identity_pool"]["test"]

      expect(pool_config).to have_key("cognito_identity_providers")
    end

    it "configures SAML provider ARNs" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_identity_pool(:test, {
          identity_pool_name: "test-identity-pool",
          saml_provider_arns: [
            "arn:aws:iam::123456789012:saml-provider/MySAMLProvider"
          ]
        })
      end

      result = synthesizer.synthesis
      pool_config = result["resource"]["aws_cognito_identity_pool"]["test"]

      expect(pool_config["saml_provider_arns"]).to eq(["arn:aws:iam::123456789012:saml-provider/MySAMLProvider"])
    end

    it "configures OpenID Connect provider ARNs" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_identity_pool(:test, {
          identity_pool_name: "test-identity-pool",
          openid_connect_provider_arns: [
            "arn:aws:iam::123456789012:oidc-provider/oidc.example.com"
          ]
        })
      end

      result = synthesizer.synthesis
      pool_config = result["resource"]["aws_cognito_identity_pool"]["test"]

      expect(pool_config["openid_connect_provider_arns"]).to eq(["arn:aws:iam::123456789012:oidc-provider/oidc.example.com"])
    end

    it "configures developer provider name" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_identity_pool(:test, {
          identity_pool_name: "test-identity-pool",
          developer_provider_name: "my-developer-provider"
        })
      end

      result = synthesizer.synthesis
      pool_config = result["resource"]["aws_cognito_identity_pool"]["test"]

      expect(pool_config["developer_provider_name"]).to eq("my-developer-provider")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_identity_pool(:test, {
          identity_pool_name: "test-identity-pool",
          allow_unauthenticated_identities: true,
          tags: { Name: "test-pool", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      pool_config = result["resource"]["aws_cognito_identity_pool"]["test"]

      expect(pool_config).to have_key("tags")
      expect(pool_config["tags"]["Name"]).to eq("test-pool")
    end

    it "applies default values correctly" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_identity_pool(:test, {
          identity_pool_name: "test-identity-pool",
          allow_unauthenticated_identities: true
        })
      end

      result = synthesizer.synthesis
      pool_config = result["resource"]["aws_cognito_identity_pool"]["test"]

      expect(pool_config["allow_unauthenticated_identities"]).to eq(true)
      expect(pool_config["allow_classic_flow"]).to eq(false)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_identity_pool(:test, {
          identity_pool_name: "test-identity-pool",
          allow_unauthenticated_identities: true
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_cognito_identity_pool"]).to be_a(Hash)
      expect(result["resource"]["aws_cognito_identity_pool"]["test"]).to be_a(Hash)

      pool_config = result["resource"]["aws_cognito_identity_pool"]["test"]
      expect(pool_config).to have_key("identity_pool_name")
      expect(pool_config["identity_pool_name"]).to be_a(String)
    end
  end

  describe "resource reference" do
    it "returns a resource reference with correct outputs" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_identity_pool(:test, {
          identity_pool_name: "test-identity-pool",
          allow_unauthenticated_identities: true
        })
      end

      expect(reference).to be_a(Pangea::Resources::ResourceReference)
      expect(reference.outputs[:id]).to eq("${aws_cognito_identity_pool.test.id}")
      expect(reference.outputs[:arn]).to eq("${aws_cognito_identity_pool.test.arn}")
    end

    it "includes computed properties for authentication methods" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_identity_pool(:test, {
          identity_pool_name: "test-identity-pool",
          cognito_identity_providers: [
            {
              client_id: "client-id-123",
              provider_name: "cognito-idp.us-east-1.amazonaws.com/us-east-1_abc123"
            }
          ]
        })
      end

      expect(reference.computed_properties[:uses_cognito_user_pools]).to eq(true)
      expect(reference.computed_properties[:has_authentication]).to eq(true)
    end

    it "indicates security level for unauthenticated pools" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_identity_pool(:test, {
          identity_pool_name: "test-identity-pool",
          allow_unauthenticated_identities: true
        })
      end

      expect(reference.computed_properties[:security_level]).to eq(:low)
    end
  end
end
