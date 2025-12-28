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
require 'pangea/resources/aws_iam_group/resource'

RSpec.describe "aws_iam_group synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_group(:test, {
          name: "test-group"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_iam_group")
      expect(result["resource"]["aws_iam_group"]).to have_key("test")

      group_config = result["resource"]["aws_iam_group"]["test"]
      expect(group_config["name"]).to eq("test-group")
      expect(group_config["path"]).to eq("/")
    end

    it "applies custom path correctly" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_group(:test, {
          name: "developers",
          path: "/teams/engineering/"
        })
      end

      result = synthesizer.synthesis
      group_config = result["resource"]["aws_iam_group"]["test"]

      expect(group_config["path"]).to eq("/teams/engineering/")
    end

    it "supports department-based groups" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_group(:test, {
          name: "engineering-developers",
          path: "/departments/engineering/"
        })
      end

      result = synthesizer.synthesis
      group_config = result["resource"]["aws_iam_group"]["test"]

      expect(group_config["name"]).to eq("engineering-developers")
      expect(group_config["path"]).to eq("/departments/engineering/")
    end

    it "supports administrative groups" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_group(:test, {
          name: "platform-admins",
          path: "/admins/"
        })
      end

      result = synthesizer.synthesis
      group_config = result["resource"]["aws_iam_group"]["test"]

      expect(group_config["name"]).to eq("platform-admins")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_group(:test, { name: "valid-group" })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_iam_group"]).to be_a(Hash)
      expect(result["resource"]["aws_iam_group"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      group_config = result["resource"]["aws_iam_group"]["test"]
      expect(group_config).to have_key("name")
      expect(group_config["name"]).to be_a(String)
    end
  end

  describe "resource references" do
    it "returns resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_group(:referenced, {
          name: "referenced-group"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq("aws_iam_group")
      expect(ref.name).to eq(:referenced)
      expect(ref.outputs[:id]).to eq("${aws_iam_group.referenced.id}")
      expect(ref.outputs[:arn]).to eq("${aws_iam_group.referenced.arn}")
      expect(ref.outputs[:name]).to eq("${aws_iam_group.referenced.name}")
      expect(ref.outputs[:unique_id]).to eq("${aws_iam_group.referenced.unique_id}")
    end

    it "provides computed properties for administrative group" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_group(:admins, {
          name: "platform-admins",
          path: "/admins/"
        })
      end

      expect(ref.administrative_group?).to be true
      expect(ref.developer_group?).to be false
      expect(ref.group_category).to eq(:administrative)
      expect(ref.security_risk_level).to eq(:high)
      expect(ref.suggested_access_level).to eq(:full_admin)
    end

    it "provides computed properties for developer group" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_group(:developers, {
          name: "backend-developers",
          path: "/teams/"
        })
      end

      expect(ref.developer_group?).to be true
      expect(ref.administrative_group?).to be false
      expect(ref.group_category).to eq(:developer)
      expect(ref.security_risk_level).to eq(:medium)
      expect(ref.suggested_access_level).to eq(:development_access)
    end

    it "provides computed properties for readonly group" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_group(:readonly, {
          name: "audit-viewers",
          path: "/readonly/"
        })
      end

      expect(ref.readonly_group?).to be true
      expect(ref.group_category).to eq(:readonly)
      expect(ref.security_risk_level).to eq(:low)
      expect(ref.suggested_access_level).to eq(:read_only)
    end

    it "provides computed properties for operations group" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_group(:ops, {
          name: "sre-team",
          path: "/operations/"
        })
      end

      expect(ref.operations_group?).to be true
      expect(ref.group_category).to eq(:operations)
      expect(ref.security_risk_level).to eq(:high)
    end

    it "detects organizational path" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_group(:org, {
          name: "team-group",
          path: "/departments/engineering/"
        })
      end

      expect(ref.organizational_path?).to be true
      expect(ref.organizational_unit).to eq("departments")
    end

    it "evaluates naming convention score" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_group(:scored, {
          name: "engineering-dev-production",
          path: "/departments/engineering/"
        })
      end

      expect(ref.follows_naming_convention?).to be true
      expect(ref.naming_convention_score).to be >= 60
    end

    it "extracts environment from name" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_group(:env, {
          name: "production-deployers"
        })
      end

      expect(ref.environment_group?).to be true
      expect(ref.extract_environment_from_name).to eq("production")
    end

    it "extracts department from name" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_iam_group(:dept, {
          name: "engineering-leads"
        })
      end

      expect(ref.department_group?).to be true
      expect(ref.extract_department_from_name).to eq("engineering")
    end
  end

  describe "common options" do
    it "supports multiple groups" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_iam_group(:developers, {
          name: "developers",
          path: "/teams/"
        })
        aws_iam_group(:admins, {
          name: "admins",
          path: "/admins/"
        })
        aws_iam_group(:readonly, {
          name: "viewers",
          path: "/readonly/"
        })
      end

      result = synthesizer.synthesis
      groups = result["resource"]["aws_iam_group"]

      expect(groups).to have_key("developers")
      expect(groups).to have_key("admins")
      expect(groups).to have_key("readonly")
      expect(groups["developers"]["path"]).to eq("/teams/")
      expect(groups["admins"]["path"]).to eq("/admins/")
      expect(groups["readonly"]["path"]).to eq("/readonly/")
    end
  end
end
