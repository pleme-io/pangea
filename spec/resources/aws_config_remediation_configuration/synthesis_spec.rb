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

RSpec.describe "aws_config_remediation_configuration synthesis" do
  include Pangea::Resources::AWS::Config

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_remediation_configuration(:test, {
          config_rule_name: "s3-bucket-public-read-prohibited",
          target_type: "SSM_DOCUMENT",
          target_id: "AWS-DisableS3BucketPublicReadWrite"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_config_remediation_configuration")
      expect(result["resource"]["aws_config_remediation_configuration"]).to have_key("test")

      remediation_config = result["resource"]["aws_config_remediation_configuration"]["test"]
      expect(remediation_config["config_rule_name"]).to eq("s3-bucket-public-read-prohibited")
      expect(remediation_config["target_type"]).to eq("SSM_DOCUMENT")
      expect(remediation_config["target_id"]).to eq("AWS-DisableS3BucketPublicReadWrite")
    end

    it "includes automatic execution" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_remediation_configuration(:test, {
          config_rule_name: "s3-bucket-public-read-prohibited",
          target_type: "SSM_DOCUMENT",
          target_id: "AWS-DisableS3BucketPublicReadWrite",
          automatic: true
        })
      end

      result = synthesizer.synthesis
      remediation_config = result["resource"]["aws_config_remediation_configuration"]["test"]

      expect(remediation_config["automatic"]).to eq(true)
    end

    it "includes maximum_automatic_attempts" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_remediation_configuration(:test, {
          config_rule_name: "s3-bucket-public-read-prohibited",
          target_type: "SSM_DOCUMENT",
          target_id: "AWS-DisableS3BucketPublicReadWrite",
          automatic: true,
          maximum_automatic_attempts: 5
        })
      end

      result = synthesizer.synthesis
      remediation_config = result["resource"]["aws_config_remediation_configuration"]["test"]

      expect(remediation_config["maximum_automatic_attempts"]).to eq(5)
    end

    it "includes retry_attempt_seconds" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_remediation_configuration(:test, {
          config_rule_name: "s3-bucket-public-read-prohibited",
          target_type: "SSM_DOCUMENT",
          target_id: "AWS-DisableS3BucketPublicReadWrite",
          automatic: true,
          retry_attempt_seconds: 60
        })
      end

      result = synthesizer.synthesis
      remediation_config = result["resource"]["aws_config_remediation_configuration"]["test"]

      expect(remediation_config["retry_attempt_seconds"]).to eq(60)
    end

    it "includes resource_type" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_remediation_configuration(:test, {
          config_rule_name: "s3-bucket-public-read-prohibited",
          target_type: "SSM_DOCUMENT",
          target_id: "AWS-DisableS3BucketPublicReadWrite",
          resource_type: "AWS::S3::Bucket"
        })
      end

      result = synthesizer.synthesis
      remediation_config = result["resource"]["aws_config_remediation_configuration"]["test"]

      expect(remediation_config["resource_type"]).to eq("AWS::S3::Bucket")
    end

    it "includes target_version" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_remediation_configuration(:test, {
          config_rule_name: "s3-bucket-public-read-prohibited",
          target_type: "SSM_DOCUMENT",
          target_id: "AWS-DisableS3BucketPublicReadWrite",
          target_version: "1"
        })
      end

      result = synthesizer.synthesis
      remediation_config = result["resource"]["aws_config_remediation_configuration"]["test"]

      expect(remediation_config["target_version"]).to eq("1")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_remediation_configuration(:test, {
          config_rule_name: "s3-bucket-public-read-prohibited",
          target_type: "SSM_DOCUMENT",
          target_id: "AWS-DisableS3BucketPublicReadWrite"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_config_remediation_configuration"]).to be_a(Hash)
      expect(result["resource"]["aws_config_remediation_configuration"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      remediation_config = result["resource"]["aws_config_remediation_configuration"]["test"]
      expect(remediation_config).to have_key("config_rule_name")
      expect(remediation_config).to have_key("target_type")
      expect(remediation_config).to have_key("target_id")
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        ref = aws_config_remediation_configuration(:test, {
          config_rule_name: "s3-bucket-public-read-prohibited",
          target_type: "SSM_DOCUMENT",
          target_id: "AWS-DisableS3BucketPublicReadWrite"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_config_remediation_configuration')
      expect(ref.name).to eq(:test)
      expect(ref.outputs).to have_key(:id)
      expect(ref.outputs).to have_key(:arn)
    end
  end
end
