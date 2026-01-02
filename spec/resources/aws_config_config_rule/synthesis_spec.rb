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
require 'pangea/resources/aws_config_config_rule/resource'

RSpec.describe "aws_config_config_rule synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for AWS managed rule" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_config_rule(:test, {
          name: "root-mfa-enabled",
          source: {
            owner: "AWS",
            source_identifier: "ROOT_MFA_ENABLED"
          }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_config_config_rule")
      expect(result["resource"]["aws_config_config_rule"]).to have_key("test")

      rule_config = result["resource"]["aws_config_config_rule"]["test"]
      expect(rule_config["name"]).to eq("root-mfa-enabled")
      expect(rule_config["source"]["owner"]).to eq("AWS")
      expect(rule_config["source"]["source_identifier"]).to eq("ROOT_MFA_ENABLED")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_config_rule(:test, {
          name: "test-rule",
          source: {
            owner: "AWS",
            source_identifier: "S3_BUCKET_SSL_REQUESTS_ONLY"
          },
          tags: { Name: "test-rule", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      rule_config = result["resource"]["aws_config_config_rule"]["test"]

      expect(rule_config).to have_key("tags")
      expect(rule_config["tags"]["Name"]).to eq("test-rule")
      expect(rule_config["tags"]["Environment"]).to eq("test")
    end

    it "includes description when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_config_rule(:test, {
          name: "test-rule",
          description: "Checks whether MFA is enabled for the root user",
          source: {
            owner: "AWS",
            source_identifier: "ROOT_MFA_ENABLED"
          }
        })
      end

      result = synthesizer.synthesis
      rule_config = result["resource"]["aws_config_config_rule"]["test"]

      expect(rule_config["description"]).to eq("Checks whether MFA is enabled for the root user")
    end

    it "includes scope configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_config_rule(:test, {
          name: "ec2-compliance",
          source: {
            owner: "AWS",
            source_identifier: "EC2_INSTANCE_NO_PUBLIC_IP"
          },
          scope: {
            compliance_resource_types: ["AWS::EC2::Instance"]
          }
        })
      end

      result = synthesizer.synthesis
      rule_config = result["resource"]["aws_config_config_rule"]["test"]

      expect(rule_config).to have_key("scope")
      expect(rule_config["scope"]["compliance_resource_types"]).to include("AWS::EC2::Instance")
    end

    it "includes maximum_execution_frequency for periodic rules" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_config_rule(:test, {
          name: "periodic-check",
          source: {
            owner: "AWS",
            source_identifier: "S3_BUCKET_PUBLIC_READ_PROHIBITED"
          },
          maximum_execution_frequency: "Six_Hours"
        })
      end

      result = synthesizer.synthesis
      rule_config = result["resource"]["aws_config_config_rule"]["test"]

      expect(rule_config["maximum_execution_frequency"]).to eq("Six_Hours")
    end

    it "includes input_parameters when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_config_rule(:test, {
          name: "test-rule",
          source: {
            owner: "AWS",
            source_identifier: "REQUIRED_TAGS"
          },
          input_parameters: '{"tag1Key":"CostCenter","tag2Key":"Environment"}'
        })
      end

      result = synthesizer.synthesis
      rule_config = result["resource"]["aws_config_config_rule"]["test"]

      expect(rule_config["input_parameters"]).to eq('{"tag1Key":"CostCenter","tag2Key":"Environment"}')
    end

    it "supports custom Lambda rule configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_config_rule(:test, {
          name: "custom-compliance",
          source: {
            owner: "CUSTOM_LAMBDA",
            source_identifier: "arn:aws:lambda:us-east-1:123456789012:function:compliance-checker"
          },
          scope: {
            compliance_resource_types: ["AWS::EC2::Instance", "AWS::S3::Bucket"]
          }
        })
      end

      result = synthesizer.synthesis
      rule_config = result["resource"]["aws_config_config_rule"]["test"]

      expect(rule_config["source"]["owner"]).to eq("CUSTOM_LAMBDA")
      expect(rule_config["source"]["source_identifier"]).to include("compliance-checker")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_config_rule(:test, {
          name: "test-rule",
          source: {
            owner: "AWS",
            source_identifier: "ROOT_MFA_ENABLED"
          }
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_config_config_rule"]).to be_a(Hash)
      expect(result["resource"]["aws_config_config_rule"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      rule_config = result["resource"]["aws_config_config_rule"]["test"]
      expect(rule_config).to have_key("name")
      expect(rule_config).to have_key("source")
      expect(rule_config["name"]).to be_a(String)
      expect(rule_config["source"]).to be_a(Hash)
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_config_config_rule(:test, {
          name: "test-rule",
          source: {
            owner: "AWS",
            source_identifier: "ROOT_MFA_ENABLED"
          }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_config_config_rule')
      expect(ref.name).to eq(:test)
      expect(ref.outputs).to have_key(:arn)
      expect(ref.outputs).to have_key(:name)
      expect(ref.outputs).to have_key(:rule_id)
    end
  end
end
