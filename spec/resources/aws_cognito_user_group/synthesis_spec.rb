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
require 'pangea/resources/aws_cognito_user_group/resource'

RSpec.describe "aws_cognito_user_group synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with required attributes" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_group(:test, {
          name: "Administrators",
          user_pool_id: "us-east-1_abc123"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_cognito_user_group")
      expect(result["resource"]["aws_cognito_user_group"]).to have_key("test")

      group_config = result["resource"]["aws_cognito_user_group"]["test"]
      expect(group_config["name"]).to eq("Administrators")
      expect(group_config["user_pool_id"]).to eq("us-east-1_abc123")
    end

    it "includes description when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_group(:test, {
          name: "Administrators",
          user_pool_id: "us-east-1_abc123",
          description: "System administrators with full access"
        })
      end

      result = synthesizer.synthesis
      group_config = result["resource"]["aws_cognito_user_group"]["test"]

      expect(group_config["description"]).to eq("System administrators with full access")
    end

    it "includes precedence when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_group(:test, {
          name: "Administrators",
          user_pool_id: "us-east-1_abc123",
          precedence: 1
        })
      end

      result = synthesizer.synthesis
      group_config = result["resource"]["aws_cognito_user_group"]["test"]

      expect(group_config["precedence"]).to eq(1)
    end

    it "includes role_arn when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_group(:test, {
          name: "Administrators",
          user_pool_id: "us-east-1_abc123",
          role_arn: "arn:aws:iam::123456789012:role/CognitoAdminRole"
        })
      end

      result = synthesizer.synthesis
      group_config = result["resource"]["aws_cognito_user_group"]["test"]

      expect(group_config["role_arn"]).to eq("arn:aws:iam::123456789012:role/CognitoAdminRole")
    end

    it "configures full admin group" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_group(:test, {
          name: "Administrators",
          user_pool_id: "us-east-1_abc123",
          description: "System administrators",
          precedence: 1,
          role_arn: "arn:aws:iam::123456789012:role/CognitoAdminRole"
        })
      end

      result = synthesizer.synthesis
      group_config = result["resource"]["aws_cognito_user_group"]["test"]

      expect(group_config["name"]).to eq("Administrators")
      expect(group_config["description"]).to eq("System administrators")
      expect(group_config["precedence"]).to eq(1)
      expect(group_config["role_arn"]).to eq("arn:aws:iam::123456789012:role/CognitoAdminRole")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_group(:test, {
          name: "Users",
          user_pool_id: "us-east-1_abc123"
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_cognito_user_group"]).to be_a(Hash)
      expect(result["resource"]["aws_cognito_user_group"]["test"]).to be_a(Hash)

      group_config = result["resource"]["aws_cognito_user_group"]["test"]
      expect(group_config).to have_key("name")
      expect(group_config).to have_key("user_pool_id")
    end
  end

  describe "resource reference" do
    it "returns a resource reference with correct outputs" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_user_group(:test, {
          name: "Administrators",
          user_pool_id: "us-east-1_abc123"
        })
      end

      expect(reference).to be_a(Pangea::Resources::ResourceReference)
      expect(reference.outputs[:name]).to eq("${aws_cognito_user_group.test.name}")
      expect(reference.outputs[:role_arn]).to eq("${aws_cognito_user_group.test.role_arn}")
    end

    it "includes computed properties for group type" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_user_group(:test, {
          name: "Administrators",
          user_pool_id: "us-east-1_abc123",
          precedence: 1,
          role_arn: "arn:aws:iam::123456789012:role/CognitoAdminRole"
        })
      end

      expect(reference.computed_properties[:has_role]).to eq(true)
      expect(reference.computed_properties[:has_precedence]).to eq(true)
      expect(reference.computed_properties[:group_type]).to eq(:privileged)
    end

    it "identifies basic groups correctly" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_user_group(:test, {
          name: "Users",
          user_pool_id: "us-east-1_abc123"
        })
      end

      expect(reference.computed_properties[:has_role]).to eq(false)
      expect(reference.computed_properties[:has_precedence]).to eq(false)
      expect(reference.computed_properties[:group_type]).to eq(:basic)
    end

    it "identifies role-based groups correctly" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_user_group(:test, {
          name: "Managers",
          user_pool_id: "us-east-1_abc123",
          role_arn: "arn:aws:iam::123456789012:role/CognitoManagerRole"
        })
      end

      expect(reference.computed_properties[:has_role]).to eq(true)
      expect(reference.computed_properties[:has_precedence]).to eq(false)
      expect(reference.computed_properties[:group_type]).to eq(:role_based)
    end
  end
end
