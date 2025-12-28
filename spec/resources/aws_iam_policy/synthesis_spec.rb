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
require 'pangea/resources/aws_iam_policy/resource'

RSpec.describe "aws_iam_policy synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_policy(:test, {
          name: "TestPolicy",
          policy: {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: "s3:GetObject",
              Resource: "arn:aws:s3:::my-bucket/*"
            }]
          }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_iam_policy")
      expect(result["resource"]["aws_iam_policy"]).to have_key("test")

      policy_config = result["resource"]["aws_iam_policy"]["test"]
      expect(policy_config["name"]).to eq("TestPolicy")
      expect(policy_config["path"]).to eq("/")
    end

    it "includes description when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_policy(:test, {
          name: "DescribedPolicy",
          description: "A policy with description",
          policy: {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: "s3:ListBucket",
              Resource: "*"
            }]
          }
        })
      end

      result = synthesizer.synthesis
      policy_config = result["resource"]["aws_iam_policy"]["test"]

      expect(policy_config).to have_key("description")
      expect(policy_config["description"]).to eq("A policy with description")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_policy(:test, {
          name: "TaggedPolicy",
          policy: {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: "s3:GetObject",
              Resource: "*"
            }]
          },
          tags: { Environment: "test", Team: "platform" }
        })
      end

      result = synthesizer.synthesis
      policy_config = result["resource"]["aws_iam_policy"]["test"]

      expect(policy_config).to have_key("tags")
      expect(policy_config["tags"]["Environment"]).to eq("test")
      expect(policy_config["tags"]["Team"]).to eq("platform")
    end

    it "applies custom path correctly" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_policy(:test, {
          name: "ServicePolicy",
          path: "/service/",
          policy: {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: "logs:CreateLogGroup",
              Resource: "*"
            }]
          }
        })
      end

      result = synthesizer.synthesis
      policy_config = result["resource"]["aws_iam_policy"]["test"]

      expect(policy_config["path"]).to eq("/service/")
    end

    it "handles multi-statement policies" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_policy(:test, {
          name: "MultiStatementPolicy",
          policy: {
            Version: "2012-10-17",
            Statement: [
              {
                Sid: "S3Access",
                Effect: "Allow",
                Action: ["s3:GetObject", "s3:PutObject"],
                Resource: "arn:aws:s3:::my-bucket/*"
              },
              {
                Sid: "EC2Describe",
                Effect: "Allow",
                Action: "ec2:Describe*",
                Resource: "*"
              }
            ]
          }
        })
      end

      result = synthesizer.synthesis
      policy_config = result["resource"]["aws_iam_policy"]["test"]

      expect(policy_config).to have_key("policy")
      parsed_policy = JSON.parse(policy_config["policy"])
      expect(parsed_policy["Statement"].length).to eq(2)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_policy(:test, {
          name: "ValidPolicy",
          policy: {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: "s3:GetObject",
              Resource: "*"
            }]
          }
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_iam_policy"]).to be_a(Hash)
      expect(result["resource"]["aws_iam_policy"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      policy_config = result["resource"]["aws_iam_policy"]["test"]
      expect(policy_config).to have_key("name")
      expect(policy_config).to have_key("policy")
      expect(policy_config["name"]).to be_a(String)
      expect(policy_config["policy"]).to be_a(String)
    end
  end

  describe "resource references" do
    it "returns resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_policy(:referenced, {
          name: "ReferencedPolicy",
          policy: {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: "s3:GetObject",
              Resource: "*"
            }]
          }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq("aws_iam_policy")
      expect(ref.name).to eq(:referenced)
      expect(ref.outputs[:id]).to eq("${aws_iam_policy.referenced.id}")
      expect(ref.outputs[:arn]).to eq("${aws_iam_policy.referenced.arn}")
      expect(ref.outputs[:name]).to eq("${aws_iam_policy.referenced.name}")
      expect(ref.outputs[:policy_id]).to eq("${aws_iam_policy.referenced.policy_id}")
    end

    it "provides computed properties via reference" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_policy(:computed, {
          name: "ComputedPolicy",
          policy: {
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Action: "s3:*",
              Resource: "*"
            }]
          }
        })
      end

      expect(ref.all_actions).to include("s3:*")
      expect(ref.all_resources).to include("*")
      expect(ref.has_wildcard_permissions?).to be true
      expect(ref.security_level).to eq(:high_risk)
    end
  end
end
