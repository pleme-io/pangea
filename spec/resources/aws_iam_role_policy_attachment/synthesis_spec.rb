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
require 'pangea/resources/aws_iam_role_policy_attachment/resource'

RSpec.describe "aws_iam_role_policy_attachment synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with AWS managed policy" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_role_policy_attachment(:test, {
          role: "my-role",
          policy_arn: "arn:aws:iam::aws:policy/ReadOnlyAccess"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_iam_role_policy_attachment")
      expect(result["resource"]["aws_iam_role_policy_attachment"]).to have_key("test")

      attachment_config = result["resource"]["aws_iam_role_policy_attachment"]["test"]
      expect(attachment_config["role"]).to eq("my-role")
      expect(attachment_config["policy_arn"]).to eq("arn:aws:iam::aws:policy/ReadOnlyAccess")
    end

    it "generates valid terraform JSON with customer managed policy" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_role_policy_attachment(:test, {
          role: "application-role",
          policy_arn: "arn:aws:iam::123456789012:policy/CustomPolicy"
        })
      end

      result = synthesizer.synthesis
      attachment_config = result["resource"]["aws_iam_role_policy_attachment"]["test"]

      expect(attachment_config["role"]).to eq("application-role")
      expect(attachment_config["policy_arn"]).to eq("arn:aws:iam::123456789012:policy/CustomPolicy")
    end

    it "supports role specified as ARN" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_role_policy_attachment(:test, {
          role: "arn:aws:iam::123456789012:role/MyRole",
          policy_arn: "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
        })
      end

      result = synthesizer.synthesis
      attachment_config = result["resource"]["aws_iam_role_policy_attachment"]["test"]

      expect(attachment_config["role"]).to eq("arn:aws:iam::123456789012:role/MyRole")
    end

    it "supports service-linked role policies" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_role_policy_attachment(:test, {
          role: "lambda-execution-role",
          policy_arn: "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        })
      end

      result = synthesizer.synthesis
      attachment_config = result["resource"]["aws_iam_role_policy_attachment"]["test"]

      expect(attachment_config["policy_arn"]).to include("service-role/AWSLambdaBasicExecutionRole")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_role_policy_attachment(:test, {
          role: "test-role",
          policy_arn: "arn:aws:iam::aws:policy/PowerUserAccess"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_iam_role_policy_attachment"]).to be_a(Hash)
      expect(result["resource"]["aws_iam_role_policy_attachment"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      attachment_config = result["resource"]["aws_iam_role_policy_attachment"]["test"]
      expect(attachment_config).to have_key("role")
      expect(attachment_config).to have_key("policy_arn")
      expect(attachment_config["role"]).to be_a(String)
      expect(attachment_config["policy_arn"]).to be_a(String)
    end
  end

  describe "resource references" do
    it "returns resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_role_policy_attachment(:referenced, {
          role: "my-role",
          policy_arn: "arn:aws:iam::aws:policy/ViewOnlyAccess"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq("aws_iam_role_policy_attachment")
      expect(ref.name).to eq(:referenced)
      expect(ref.outputs[:id]).to eq("${aws_iam_role_policy_attachment.referenced.id}")
      expect(ref.outputs[:role]).to eq("${aws_iam_role_policy_attachment.referenced.role}")
      expect(ref.outputs[:policy_arn]).to eq("${aws_iam_role_policy_attachment.referenced.policy_arn}")
    end

    it "provides computed properties via reference for AWS managed policy" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_role_policy_attachment(:computed, {
          role: "admin-role",
          policy_arn: "arn:aws:iam::aws:policy/AdministratorAccess"
        })
      end

      expect(ref.aws_managed_policy?).to be true
      expect(ref.customer_managed_policy?).to be false
      expect(ref.policy_name).to eq("AdministratorAccess")
      expect(ref.role_name).to eq("admin-role")
      expect(ref.potentially_dangerous?).to be true
      expect(ref.policy_category).to eq(:administrative)
      expect(ref.security_risk_level).to eq(:high)
    end

    it "provides computed properties via reference for customer managed policy" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_role_policy_attachment(:custom, {
          role: "app-role",
          policy_arn: "arn:aws:iam::123456789012:policy/AppPolicy"
        })
      end

      expect(ref.aws_managed_policy?).to be false
      expect(ref.customer_managed_policy?).to be true
      expect(ref.policy_name).to eq("AppPolicy")
      expect(ref.policy_account_id).to eq("123456789012")
      expect(ref.security_risk_level).to eq(:medium)
    end

    it "detects role specified by ARN" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_role_policy_attachment(:arn_role, {
          role: "arn:aws:iam::123456789012:role/CrossAccountRole",
          policy_arn: "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
        })
      end

      expect(ref.role_specified_by_arn?).to be true
      expect(ref.role_name).to eq("CrossAccountRole")
    end
  end

  describe "common options" do
    it "supports multiple attachments to same role" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_role_policy_attachment(:s3_access, {
          role: "lambda-role",
          policy_arn: "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
        })
        aws_iam_role_policy_attachment(:cloudwatch_access, {
          role: "lambda-role",
          policy_arn: "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
        })
      end

      result = synthesizer.synthesis
      attachments = result["resource"]["aws_iam_role_policy_attachment"]

      expect(attachments).to have_key("s3_access")
      expect(attachments).to have_key("cloudwatch_access")
      expect(attachments["s3_access"]["role"]).to eq("lambda-role")
      expect(attachments["cloudwatch_access"]["role"]).to eq("lambda-role")
    end
  end
end
