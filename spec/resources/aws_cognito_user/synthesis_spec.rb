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
require 'pangea/resources/aws_cognito_user/resource'

RSpec.describe "aws_cognito_user synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with required attributes" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user(:test, {
          username: "testuser",
          user_pool_id: "us-east-1_abc123"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_cognito_user")
      expect(result["resource"]["aws_cognito_user"]).to have_key("test")

      user_config = result["resource"]["aws_cognito_user"]["test"]
      expect(user_config["username"]).to eq("testuser")
      expect(user_config["user_pool_id"]).to eq("us-east-1_abc123")
    end

    it "includes user attributes when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user(:test, {
          username: "testuser",
          user_pool_id: "us-east-1_abc123",
          attributes: {
            "email" => "testuser@example.com",
            "email_verified" => "true",
            "name" => "Test User"
          }
        })
      end

      result = synthesizer.synthesis
      user_config = result["resource"]["aws_cognito_user"]["test"]

      expect(user_config).to have_key("attributes")
    end

    it "includes temporary password when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user(:test, {
          username: "testuser",
          user_pool_id: "us-east-1_abc123",
          temporary_password: "TempPass123!"
        })
      end

      result = synthesizer.synthesis
      user_config = result["resource"]["aws_cognito_user"]["test"]

      expect(user_config["temporary_password"]).to eq("TempPass123!")
    end

    it "configures message action" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user(:test, {
          username: "testuser",
          user_pool_id: "us-east-1_abc123",
          message_action: "SUPPRESS"
        })
      end

      result = synthesizer.synthesis
      user_config = result["resource"]["aws_cognito_user"]["test"]

      expect(user_config["message_action"]).to eq("SUPPRESS")
    end

    it "configures desired delivery mediums" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user(:test, {
          username: "testuser",
          user_pool_id: "us-east-1_abc123",
          attributes: {
            "email" => "testuser@example.com"
          },
          desired_delivery_mediums: ["EMAIL"]
        })
      end

      result = synthesizer.synthesis
      user_config = result["resource"]["aws_cognito_user"]["test"]

      expect(user_config["desired_delivery_mediums"]).to eq(["EMAIL"])
    end

    it "applies default values correctly" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user(:test, {
          username: "testuser",
          user_pool_id: "us-east-1_abc123"
        })
      end

      result = synthesizer.synthesis
      user_config = result["resource"]["aws_cognito_user"]["test"]

      expect(user_config["force_alias_creation"]).to eq(false)
    end

    it "configures force alias creation" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user(:test, {
          username: "testuser",
          user_pool_id: "us-east-1_abc123",
          force_alias_creation: true
        })
      end

      result = synthesizer.synthesis
      user_config = result["resource"]["aws_cognito_user"]["test"]

      expect(user_config["force_alias_creation"]).to eq(true)
    end

    it "configures full admin user" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user(:test, {
          username: "admin-user",
          user_pool_id: "us-east-1_abc123",
          attributes: {
            "email" => "admin@example.com",
            "email_verified" => "true",
            "name" => "Admin User",
            "custom:role" => "admin"
          },
          temporary_password: "AdminPass123!",
          desired_delivery_mediums: ["EMAIL"],
          force_alias_creation: true
        })
      end

      result = synthesizer.synthesis
      user_config = result["resource"]["aws_cognito_user"]["test"]

      expect(user_config["username"]).to eq("admin-user")
      expect(user_config["temporary_password"]).to eq("AdminPass123!")
      expect(user_config["force_alias_creation"]).to eq(true)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user(:test, {
          username: "testuser",
          user_pool_id: "us-east-1_abc123"
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_cognito_user"]).to be_a(Hash)
      expect(result["resource"]["aws_cognito_user"]["test"]).to be_a(Hash)

      user_config = result["resource"]["aws_cognito_user"]["test"]
      expect(user_config).to have_key("username")
      expect(user_config).to have_key("user_pool_id")
    end
  end

  describe "resource reference" do
    it "returns a resource reference with correct outputs" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_user(:test, {
          username: "testuser",
          user_pool_id: "us-east-1_abc123"
        })
      end

      expect(reference).to be_a(Pangea::Resources::ResourceReference)
      expect(reference.outputs[:username]).to eq("${aws_cognito_user.test.username}")
      expect(reference.outputs[:status]).to eq("${aws_cognito_user.test.status}")
      expect(reference.outputs[:sub]).to eq("${aws_cognito_user.test.sub}")
    end

    it "includes computed properties for user attributes" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_user(:test, {
          username: "testuser",
          user_pool_id: "us-east-1_abc123",
          attributes: {
            "email" => "testuser@example.com",
            "phone_number" => "+15551234567"
          }
        })
      end

      expect(reference.computed_properties[:has_email]).to eq(true)
      expect(reference.computed_properties[:has_phone_number]).to eq(true)
    end

    it "identifies custom attributes correctly" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_user(:test, {
          username: "testuser",
          user_pool_id: "us-east-1_abc123",
          attributes: {
            "email" => "testuser@example.com",
            "custom:role" => "admin",
            "custom:department" => "engineering"
          }
        })
      end

      expect(reference.computed_properties[:has_custom_attributes]).to eq(true)
      expect(reference.computed_properties[:custom_attributes]).to eq({
        "custom:role" => "admin",
        "custom:department" => "engineering"
      })
    end

    it "separates standard and custom attributes" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_user(:test, {
          username: "testuser",
          user_pool_id: "us-east-1_abc123",
          attributes: {
            "email" => "testuser@example.com",
            "name" => "Test User",
            "custom:role" => "user"
          }
        })
      end

      expect(reference.computed_properties[:standard_attributes]).to eq({
        "email" => "testuser@example.com",
        "name" => "Test User"
      })
      expect(reference.computed_properties[:custom_attributes]).to eq({
        "custom:role" => "user"
      })
    end
  end
end
