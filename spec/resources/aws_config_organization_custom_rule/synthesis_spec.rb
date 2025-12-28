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

RSpec.describe "aws_config_organization_custom_rule synthesis" do
  include Pangea::Resources::AWS::Config

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_custom_rule(:test, {
          name: "organization-custom-rule",
          lambda_function_arn: "arn:aws:lambda:us-east-1:123456789012:function:config-rule",
          trigger_types: ["ConfigurationItemChangeNotification"]
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_config_organization_custom_rule")
      expect(result["resource"]["aws_config_organization_custom_rule"]).to have_key("test")

      rule_config = result["resource"]["aws_config_organization_custom_rule"]["test"]
      expect(rule_config["name"]).to eq("organization-custom-rule")
      expect(rule_config["lambda_function_arn"]).to include("config-rule")
    end

    it "includes description when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_custom_rule(:test, {
          name: "organization-custom-rule",
          lambda_function_arn: "arn:aws:lambda:us-east-1:123456789012:function:config-rule",
          trigger_types: ["ConfigurationItemChangeNotification"],
          description: "Custom organization rule for compliance checking"
        })
      end

      result = synthesizer.synthesis
      rule_config = result["resource"]["aws_config_organization_custom_rule"]["test"]

      expect(rule_config["description"]).to eq("Custom organization rule for compliance checking")
    end

    it "includes excluded_accounts configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_custom_rule(:test, {
          name: "organization-custom-rule",
          lambda_function_arn: "arn:aws:lambda:us-east-1:123456789012:function:config-rule",
          trigger_types: ["ConfigurationItemChangeNotification"],
          excluded_accounts: ["111111111111"]
        })
      end

      result = synthesizer.synthesis
      rule_config = result["resource"]["aws_config_organization_custom_rule"]["test"]

      expect(rule_config).to have_key("excluded_accounts")
    end

    it "includes input_parameters when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_custom_rule(:test, {
          name: "organization-custom-rule",
          lambda_function_arn: "arn:aws:lambda:us-east-1:123456789012:function:config-rule",
          trigger_types: ["ConfigurationItemChangeNotification"],
          input_parameters: '{"key":"value"}'
        })
      end

      result = synthesizer.synthesis
      rule_config = result["resource"]["aws_config_organization_custom_rule"]["test"]

      expect(rule_config["input_parameters"]).to eq('{"key":"value"}')
    end

    it "includes resource_types_scope" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_custom_rule(:test, {
          name: "organization-custom-rule",
          lambda_function_arn: "arn:aws:lambda:us-east-1:123456789012:function:config-rule",
          trigger_types: ["ConfigurationItemChangeNotification"],
          resource_types_scope: ["AWS::EC2::Instance", "AWS::S3::Bucket"]
        })
      end

      result = synthesizer.synthesis
      rule_config = result["resource"]["aws_config_organization_custom_rule"]["test"]

      expect(rule_config).to have_key("resource_types_scope")
    end

    it "includes maximum_execution_frequency" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_custom_rule(:test, {
          name: "organization-custom-rule",
          lambda_function_arn: "arn:aws:lambda:us-east-1:123456789012:function:config-rule",
          trigger_types: ["ScheduledNotification"],
          maximum_execution_frequency: "TwentyFour_Hours"
        })
      end

      result = synthesizer.synthesis
      rule_config = result["resource"]["aws_config_organization_custom_rule"]["test"]

      expect(rule_config["maximum_execution_frequency"]).to eq("TwentyFour_Hours")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_custom_rule(:test, {
          name: "organization-custom-rule",
          lambda_function_arn: "arn:aws:lambda:us-east-1:123456789012:function:config-rule",
          trigger_types: ["ConfigurationItemChangeNotification"]
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_config_organization_custom_rule"]).to be_a(Hash)
      expect(result["resource"]["aws_config_organization_custom_rule"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      rule_config = result["resource"]["aws_config_organization_custom_rule"]["test"]
      expect(rule_config).to have_key("name")
      expect(rule_config).to have_key("lambda_function_arn")
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        ref = aws_config_organization_custom_rule(:test, {
          name: "organization-custom-rule",
          lambda_function_arn: "arn:aws:lambda:us-east-1:123456789012:function:config-rule",
          trigger_types: ["ConfigurationItemChangeNotification"]
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_config_organization_custom_rule')
      expect(ref.name).to eq(:test)
      expect(ref.outputs).to have_key(:id)
      expect(ref.outputs).to have_key(:arn)
    end
  end
end
