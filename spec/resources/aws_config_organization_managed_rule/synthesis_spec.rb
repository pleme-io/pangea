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
require 'pangea/resources/aws/config'

RSpec.describe "aws_config_organization_managed_rule synthesis" do
  include Pangea::Resources::AWS::Config

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_managed_rule(:test, {
          name: "organization-managed-rule",
          rule_identifier: "IAM_PASSWORD_POLICY"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_config_organization_managed_rule")
      expect(result["resource"]["aws_config_organization_managed_rule"]).to have_key("test")

      rule_config = result["resource"]["aws_config_organization_managed_rule"]["test"]
      expect(rule_config["name"]).to eq("organization-managed-rule")
      expect(rule_config["rule_identifier"]).to eq("IAM_PASSWORD_POLICY")
    end

    it "includes description when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_managed_rule(:test, {
          name: "organization-managed-rule",
          rule_identifier: "IAM_PASSWORD_POLICY",
          description: "Checks IAM password policy compliance"
        })
      end

      result = synthesizer.synthesis
      rule_config = result["resource"]["aws_config_organization_managed_rule"]["test"]

      expect(rule_config["description"]).to eq("Checks IAM password policy compliance")
    end

    it "includes excluded_accounts configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_managed_rule(:test, {
          name: "organization-managed-rule",
          rule_identifier: "IAM_PASSWORD_POLICY",
          excluded_accounts: ["111111111111", "222222222222"]
        })
      end

      result = synthesizer.synthesis
      rule_config = result["resource"]["aws_config_organization_managed_rule"]["test"]

      expect(rule_config).to have_key("excluded_accounts")
    end

    it "includes input_parameters when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_managed_rule(:test, {
          name: "organization-managed-rule",
          rule_identifier: "IAM_PASSWORD_POLICY",
          input_parameters: '{"RequireUppercaseCharacters":"true","RequireLowercaseCharacters":"true"}'
        })
      end

      result = synthesizer.synthesis
      rule_config = result["resource"]["aws_config_organization_managed_rule"]["test"]

      expect(rule_config["input_parameters"]).to include("RequireUppercaseCharacters")
    end

    it "includes resource_types_scope" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_managed_rule(:test, {
          name: "organization-managed-rule",
          rule_identifier: "EC2_INSTANCE_NO_PUBLIC_IP",
          resource_types_scope: ["AWS::EC2::Instance"]
        })
      end

      result = synthesizer.synthesis
      rule_config = result["resource"]["aws_config_organization_managed_rule"]["test"]

      expect(rule_config).to have_key("resource_types_scope")
    end

    it "includes maximum_execution_frequency" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_managed_rule(:test, {
          name: "organization-managed-rule",
          rule_identifier: "IAM_PASSWORD_POLICY",
          maximum_execution_frequency: "TwentyFour_Hours"
        })
      end

      result = synthesizer.synthesis
      rule_config = result["resource"]["aws_config_organization_managed_rule"]["test"]

      expect(rule_config["maximum_execution_frequency"]).to eq("TwentyFour_Hours")
    end

    it "includes tag_key_scope and tag_value_scope" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_managed_rule(:test, {
          name: "organization-managed-rule",
          rule_identifier: "REQUIRED_TAGS",
          tag_key_scope: "Environment",
          tag_value_scope: "Production"
        })
      end

      result = synthesizer.synthesis
      rule_config = result["resource"]["aws_config_organization_managed_rule"]["test"]

      expect(rule_config["tag_key_scope"]).to eq("Environment")
      expect(rule_config["tag_value_scope"]).to eq("Production")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_managed_rule(:test, {
          name: "organization-managed-rule",
          rule_identifier: "IAM_PASSWORD_POLICY"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_config_organization_managed_rule"]).to be_a(Hash)
      expect(result["resource"]["aws_config_organization_managed_rule"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      rule_config = result["resource"]["aws_config_organization_managed_rule"]["test"]
      expect(rule_config).to have_key("name")
      expect(rule_config).to have_key("rule_identifier")
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        ref = aws_config_organization_managed_rule(:test, {
          name: "organization-managed-rule",
          rule_identifier: "IAM_PASSWORD_POLICY"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_config_organization_managed_rule')
      expect(ref.name).to eq(:test)
      expect(ref.outputs).to have_key(:id)
      expect(ref.outputs).to have_key(:arn)
    end
  end
end
