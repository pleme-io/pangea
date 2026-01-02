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
require 'pangea/resources/aws_cognito_identity_provider/resource'

RSpec.describe "aws_cognito_identity_provider synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for Google provider" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_identity_provider(:test, {
          provider_name: "Google",
          provider_type: "Google",
          user_pool_id: "us-east-1_abc123",
          provider_details: {
            "client_id" => "123456789-abc.apps.googleusercontent.com",
            "client_secret" => "test-secret",
            "authorize_scopes" => "profile email openid"
          },
          attribute_mapping: {
            "email" => "email",
            "given_name" => "given_name",
            "family_name" => "family_name"
          }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_cognito_identity_provider")
      expect(result["resource"]["aws_cognito_identity_provider"]).to have_key("test")

      provider_config = result["resource"]["aws_cognito_identity_provider"]["test"]
      expect(provider_config["provider_name"]).to eq("Google")
      expect(provider_config["provider_type"]).to eq("Google")
      expect(provider_config["user_pool_id"]).to eq("us-east-1_abc123")
    end

    it "generates valid terraform JSON for Facebook provider" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_identity_provider(:test, {
          provider_name: "Facebook",
          provider_type: "Facebook",
          user_pool_id: "us-east-1_abc123",
          provider_details: {
            "client_id" => "123456789012345",
            "client_secret" => "abcdef0123456789abcdef0123456789",
            "authorize_scopes" => "public_profile email"
          }
        })
      end

      result = synthesizer.synthesis
      provider_config = result["resource"]["aws_cognito_identity_provider"]["test"]

      expect(provider_config["provider_type"]).to eq("Facebook")
      expect(provider_config).to have_key("provider_details")
    end

    it "generates valid terraform JSON for SAML provider" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_identity_provider(:test, {
          provider_name: "MySAMLProvider",
          provider_type: "SAML",
          user_pool_id: "us-east-1_abc123",
          provider_details: {
            "MetadataURL" => "https://idp.example.com/saml/metadata"
          },
          idp_identifiers: ["MySAMLProvider", "enterprise-sso"]
        })
      end

      result = synthesizer.synthesis
      provider_config = result["resource"]["aws_cognito_identity_provider"]["test"]

      expect(provider_config["provider_type"]).to eq("SAML")
      expect(provider_config["idp_identifiers"]).to eq(["MySAMLProvider", "enterprise-sso"])
    end

    it "generates valid terraform JSON for OIDC provider" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_identity_provider(:test, {
          provider_name: "MyOIDCProvider",
          provider_type: "OIDC",
          user_pool_id: "us-east-1_abc123",
          provider_details: {
            "client_id" => "oidc-client-id",
            "client_secret" => "oidc-client-secret",
            "oidc_issuer" => "https://oidc.example.com",
            "authorize_scopes" => "openid email profile"
          }
        })
      end

      result = synthesizer.synthesis
      provider_config = result["resource"]["aws_cognito_identity_provider"]["test"]

      expect(provider_config["provider_type"]).to eq("OIDC")
    end

    it "includes attribute mapping when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_identity_provider(:test, {
          provider_name: "Google",
          provider_type: "Google",
          user_pool_id: "us-east-1_abc123",
          provider_details: {
            "client_id" => "123456789-abc.apps.googleusercontent.com",
            "client_secret" => "test-secret",
            "authorize_scopes" => "profile email openid"
          },
          attribute_mapping: {
            "email" => "email",
            "given_name" => "given_name"
          }
        })
      end

      result = synthesizer.synthesis
      provider_config = result["resource"]["aws_cognito_identity_provider"]["test"]

      expect(provider_config).to have_key("attribute_mapping")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_identity_provider(:test, {
          provider_name: "Google",
          provider_type: "Google",
          user_pool_id: "us-east-1_abc123",
          provider_details: {
            "client_id" => "123456789-abc.apps.googleusercontent.com",
            "client_secret" => "test-secret",
            "authorize_scopes" => "profile email openid"
          }
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_cognito_identity_provider"]).to be_a(Hash)
      expect(result["resource"]["aws_cognito_identity_provider"]["test"]).to be_a(Hash)

      provider_config = result["resource"]["aws_cognito_identity_provider"]["test"]
      expect(provider_config).to have_key("provider_name")
      expect(provider_config).to have_key("provider_type")
      expect(provider_config).to have_key("user_pool_id")
    end
  end

  describe "resource reference" do
    it "returns a resource reference with correct outputs" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_identity_provider(:test, {
          provider_name: "Google",
          provider_type: "Google",
          user_pool_id: "us-east-1_abc123",
          provider_details: {
            "client_id" => "123456789-abc.apps.googleusercontent.com",
            "client_secret" => "test-secret",
            "authorize_scopes" => "profile email openid"
          }
        })
      end

      expect(reference).to be_a(Pangea::Resources::ResourceReference)
      expect(reference.outputs[:provider_name]).to eq("${aws_cognito_identity_provider.test.provider_name}")
      expect(reference.outputs[:provider_type]).to eq("${aws_cognito_identity_provider.test.provider_type}")
    end

    it "includes computed properties for provider type" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_identity_provider(:test, {
          provider_name: "Google",
          provider_type: "Google",
          user_pool_id: "us-east-1_abc123",
          provider_details: {
            "client_id" => "123456789-abc.apps.googleusercontent.com",
            "client_secret" => "test-secret",
            "authorize_scopes" => "profile email openid"
          }
        })
      end

      expect(reference.computed_properties[:social_provider]).to eq(true)
      expect(reference.computed_properties[:oauth_provider]).to eq(true)
      expect(reference.computed_properties[:provider_category]).to eq(:social)
    end

    it "identifies enterprise providers correctly" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_identity_provider(:test, {
          provider_name: "MySAMLProvider",
          provider_type: "SAML",
          user_pool_id: "us-east-1_abc123",
          provider_details: {
            "MetadataURL" => "https://idp.example.com/saml/metadata"
          }
        })
      end

      expect(reference.computed_properties[:enterprise_provider]).to eq(true)
      expect(reference.computed_properties[:saml_provider]).to eq(true)
      expect(reference.computed_properties[:provider_category]).to eq(:enterprise)
    end
  end
end
