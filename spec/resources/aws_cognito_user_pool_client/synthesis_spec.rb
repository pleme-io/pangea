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
require 'pangea/resources/aws_cognito_user_pool_client/resource'

RSpec.describe "aws_cognito_user_pool_client synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with required attributes" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool_client(:test, {
          name: "test-client",
          user_pool_id: "us-east-1_abc123"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_cognito_user_pool_client")
      expect(result["resource"]["aws_cognito_user_pool_client"]).to have_key("test")

      client_config = result["resource"]["aws_cognito_user_pool_client"]["test"]
      expect(client_config["name"]).to eq("test-client")
      expect(client_config["user_pool_id"]).to eq("us-east-1_abc123")
    end

    it "configures OAuth flows correctly" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool_client(:test, {
          name: "test-client",
          user_pool_id: "us-east-1_abc123",
          allowed_oauth_flows: ["code"],
          allowed_oauth_flows_user_pool_client: true,
          allowed_oauth_scopes: ["phone", "email", "openid", "profile"],
          callback_urls: ["https://example.com/callback"],
          logout_urls: ["https://example.com/logout"]
        })
      end

      result = synthesizer.synthesis
      client_config = result["resource"]["aws_cognito_user_pool_client"]["test"]

      expect(client_config["allowed_oauth_flows"]).to eq(["code"])
      expect(client_config["allowed_oauth_flows_user_pool_client"]).to eq(true)
      expect(client_config["allowed_oauth_scopes"]).to include("openid")
      expect(client_config["callback_urls"]).to eq(["https://example.com/callback"])
    end

    it "configures explicit auth flows" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool_client(:test, {
          name: "test-client",
          user_pool_id: "us-east-1_abc123",
          explicit_auth_flows: ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
        })
      end

      result = synthesizer.synthesis
      client_config = result["resource"]["aws_cognito_user_pool_client"]["test"]

      expect(client_config["explicit_auth_flows"]).to include("ALLOW_USER_SRP_AUTH")
      expect(client_config["explicit_auth_flows"]).to include("ALLOW_REFRESH_TOKEN_AUTH")
    end

    it "configures token validity settings" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool_client(:test, {
          name: "test-client",
          user_pool_id: "us-east-1_abc123",
          access_token_validity: 60,
          id_token_validity: 60,
          refresh_token_validity: 30,
          token_validity_units: {
            access_token: "minutes",
            id_token: "minutes",
            refresh_token: "days"
          }
        })
      end

      result = synthesizer.synthesis
      client_config = result["resource"]["aws_cognito_user_pool_client"]["test"]

      expect(client_config["access_token_validity"]).to eq(60)
      expect(client_config["id_token_validity"]).to eq(60)
      expect(client_config["refresh_token_validity"]).to eq(30)
      expect(client_config).to have_key("token_validity_units")
    end

    it "applies default values correctly" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool_client(:test, {
          name: "test-client",
          user_pool_id: "us-east-1_abc123"
        })
      end

      result = synthesizer.synthesis
      client_config = result["resource"]["aws_cognito_user_pool_client"]["test"]

      expect(client_config["generate_secret"]).to eq(false)
      expect(client_config["enable_token_revocation"]).to eq(true)
      expect(client_config["allowed_oauth_flows_user_pool_client"]).to eq(false)
    end

    it "supports generate_secret configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool_client(:test, {
          name: "test-client",
          user_pool_id: "us-east-1_abc123",
          generate_secret: true
        })
      end

      result = synthesizer.synthesis
      client_config = result["resource"]["aws_cognito_user_pool_client"]["test"]

      expect(client_config["generate_secret"]).to eq(true)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool_client(:test, {
          name: "test-client",
          user_pool_id: "us-east-1_abc123"
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_cognito_user_pool_client"]).to be_a(Hash)
      expect(result["resource"]["aws_cognito_user_pool_client"]["test"]).to be_a(Hash)

      client_config = result["resource"]["aws_cognito_user_pool_client"]["test"]
      expect(client_config).to have_key("name")
      expect(client_config).to have_key("user_pool_id")
    end
  end

  describe "resource reference" do
    it "returns a resource reference with correct outputs" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_user_pool_client(:test, {
          name: "test-client",
          user_pool_id: "us-east-1_abc123"
        })
      end

      expect(reference).to be_a(Pangea::Resources::ResourceReference)
      expect(reference.outputs[:id]).to eq("${aws_cognito_user_pool_client.test.id}")
      expect(reference.outputs[:client_secret]).to eq("${aws_cognito_user_pool_client.test.client_secret}")
    end

    it "includes computed properties for client type" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_user_pool_client(:test, {
          name: "test-client",
          user_pool_id: "us-east-1_abc123",
          generate_secret: false
        })
      end

      expect(reference.computed_properties[:public_client]).to eq(true)
      expect(reference.computed_properties[:confidential_client]).to eq(false)
    end
  end
end
