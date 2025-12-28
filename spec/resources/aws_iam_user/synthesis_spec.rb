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
require 'pangea/resources/aws_iam_user/resource'

RSpec.describe "aws_iam_user synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_user(:test, {
          name: "test-user"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_iam_user")
      expect(result["resource"]["aws_iam_user"]).to have_key("test")

      user_config = result["resource"]["aws_iam_user"]["test"]
      expect(user_config["name"]).to eq("test-user")
      expect(user_config["path"]).to eq("/")
      expect(user_config["force_destroy"]).to eq(false)
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_user(:test, {
          name: "tagged-user",
          tags: { Environment: "test", Team: "platform" }
        })
      end

      result = synthesizer.synthesis
      user_config = result["resource"]["aws_iam_user"]["test"]

      expect(user_config).to have_key("tags")
      expect(user_config["tags"]["Environment"]).to eq("test")
      expect(user_config["tags"]["Team"]).to eq("platform")
    end

    it "applies custom path correctly" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_user(:test, {
          name: "service-user",
          path: "/service-accounts/"
        })
      end

      result = synthesizer.synthesis
      user_config = result["resource"]["aws_iam_user"]["test"]

      expect(user_config["path"]).to eq("/service-accounts/")
    end

    it "supports permissions boundary" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_user(:test, {
          name: "bounded-user",
          permissions_boundary: "arn:aws:iam::123456789012:policy/DeveloperBoundary"
        })
      end

      result = synthesizer.synthesis
      user_config = result["resource"]["aws_iam_user"]["test"]

      expect(user_config["permissions_boundary"]).to eq("arn:aws:iam::123456789012:policy/DeveloperBoundary")
    end

    it "supports force_destroy option" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_user(:test, {
          name: "deletable-user",
          force_destroy: true
        })
      end

      result = synthesizer.synthesis
      user_config = result["resource"]["aws_iam_user"]["test"]

      expect(user_config["force_destroy"]).to eq(true)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_user(:test, { name: "valid-user" })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_iam_user"]).to be_a(Hash)
      expect(result["resource"]["aws_iam_user"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      user_config = result["resource"]["aws_iam_user"]["test"]
      expect(user_config).to have_key("name")
      expect(user_config["name"]).to be_a(String)
    end
  end

  describe "resource references" do
    it "returns resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_user(:referenced, {
          name: "referenced-user"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq("aws_iam_user")
      expect(ref.name).to eq(:referenced)
      expect(ref.outputs[:id]).to eq("${aws_iam_user.referenced.id}")
      expect(ref.outputs[:arn]).to eq("${aws_iam_user.referenced.arn}")
      expect(ref.outputs[:name]).to eq("${aws_iam_user.referenced.name}")
      expect(ref.outputs[:unique_id]).to eq("${aws_iam_user.referenced.unique_id}")
    end

    it "provides computed properties for service user" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_user(:service, {
          name: "app-service-user",
          path: "/service-accounts/"
        })
      end

      expect(ref.service_user?).to be true
      expect(ref.administrative_user?).to be false
      expect(ref.user_category).to eq(:service_account)
      expect(ref.organizational_path?).to be true
      expect(ref.organizational_unit).to eq("service-accounts")
    end

    it "provides computed properties for admin user" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_user(:admin, {
          name: "admin-user",
          permissions_boundary: "arn:aws:iam::123456789012:policy/AdminBoundary"
        })
      end

      expect(ref.administrative_user?).to be true
      expect(ref.has_permissions_boundary?).to be true
      expect(ref.permissions_boundary_policy_name).to eq("AdminBoundary")
      expect(ref.security_risk_level).to eq(:low)
    end

    it "provides computed properties for user without boundary" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_user(:unbounded, {
          name: "admin-user"
        })
      end

      expect(ref.administrative_user?).to be true
      expect(ref.has_permissions_boundary?).to be false
      expect(ref.security_risk_level).to eq(:high)
    end

    it "detects human users" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_user(:human, {
          name: "john.doe"
        })
      end

      expect(ref.human_user?).to be true
      expect(ref.service_user?).to be false
      expect(ref.user_category).to eq(:human_user)
    end
  end

  describe "common options" do
    it "supports full user configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_user(:full, {
          name: "full-user",
          path: "/developers/",
          permissions_boundary: "arn:aws:iam::123456789012:policy/DevBoundary",
          force_destroy: true,
          tags: {
            Department: "Engineering",
            CostCenter: "12345"
          }
        })
      end

      result = synthesizer.synthesis
      user_config = result["resource"]["aws_iam_user"]["full"]

      expect(user_config["name"]).to eq("full-user")
      expect(user_config["path"]).to eq("/developers/")
      expect(user_config["permissions_boundary"]).to eq("arn:aws:iam::123456789012:policy/DevBoundary")
      expect(user_config["force_destroy"]).to eq(true)
      expect(user_config["tags"]["Department"]).to eq("Engineering")
    end
  end
end
