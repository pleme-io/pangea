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

RSpec.describe "aws_config_organization_conformance_pack synthesis" do
  include Pangea::Resources::AWS::Config

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with template_s3_uri" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_conformance_pack(:test, {
          name: "SecurityConformancePack",
          template_s3_uri: "s3://config-conformance-packs/security-pack.yaml"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_config_organization_conformance_pack")
      expect(result["resource"]["aws_config_organization_conformance_pack"]).to have_key("test")

      pack_config = result["resource"]["aws_config_organization_conformance_pack"]["test"]
      expect(pack_config["name"]).to eq("SecurityConformancePack")
      expect(pack_config["template_s3_uri"]).to eq("s3://config-conformance-packs/security-pack.yaml")
    end

    it "includes template_body configuration" do
      template_body = <<~YAML
        Resources:
          MFAEnabled:
            Type: AWS::Config::ConfigRule
      YAML

      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_conformance_pack(:test, {
          name: "InlineConformancePack",
          template_body: template_body
        })
      end

      result = synthesizer.synthesis
      pack_config = result["resource"]["aws_config_organization_conformance_pack"]["test"]

      expect(pack_config["template_body"]).to include("AWS::Config::ConfigRule")
    end

    it "includes delivery S3 configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_conformance_pack(:test, {
          name: "SecurityConformancePack",
          template_s3_uri: "s3://config-conformance-packs/security-pack.yaml",
          delivery_s3_bucket: "organization-config-delivery",
          delivery_s3_key_prefix: "conformance-packs/"
        })
      end

      result = synthesizer.synthesis
      pack_config = result["resource"]["aws_config_organization_conformance_pack"]["test"]

      expect(pack_config["delivery_s3_bucket"]).to eq("organization-config-delivery")
      expect(pack_config["delivery_s3_key_prefix"]).to eq("conformance-packs/")
    end

    it "includes excluded_accounts configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_conformance_pack(:test, {
          name: "SecurityConformancePack",
          template_s3_uri: "s3://config-conformance-packs/security-pack.yaml",
          excluded_accounts: ["111111111111", "222222222222"]
        })
      end

      result = synthesizer.synthesis
      pack_config = result["resource"]["aws_config_organization_conformance_pack"]["test"]

      expect(pack_config).to have_key("excluded_accounts")
    end

    it "includes conformance_pack_input_parameters" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_conformance_pack(:test, {
          name: "SecurityConformancePack",
          template_s3_uri: "s3://config-conformance-packs/security-pack.yaml",
          conformance_pack_input_parameters: [
            { parameter_name: "SecurityLevel", parameter_value: "High" },
            { parameter_name: "NotificationEmail", parameter_value: "security@company.com" }
          ]
        })
      end

      result = synthesizer.synthesis
      pack_config = result["resource"]["aws_config_organization_conformance_pack"]["test"]

      expect(pack_config).to have_key("conformance_pack_input_parameters")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_organization_conformance_pack(:test, {
          name: "SecurityConformancePack",
          template_s3_uri: "s3://config-conformance-packs/security-pack.yaml"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_config_organization_conformance_pack"]).to be_a(Hash)
      expect(result["resource"]["aws_config_organization_conformance_pack"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      pack_config = result["resource"]["aws_config_organization_conformance_pack"]["test"]
      expect(pack_config).to have_key("name")
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        ref = aws_config_organization_conformance_pack(:test, {
          name: "SecurityConformancePack",
          template_s3_uri: "s3://config-conformance-packs/security-pack.yaml"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_config_organization_conformance_pack')
      expect(ref.name).to eq(:test)
      expect(ref.outputs).to have_key(:id)
      expect(ref.outputs).to have_key(:arn)
    end

    it "includes computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        ref = aws_config_organization_conformance_pack(:test, {
          name: "SecurityConformancePack",
          template_s3_uri: "s3://config-conformance-packs/security-pack.yaml",
          conformance_pack_input_parameters: [
            { parameter_name: "SecurityLevel", parameter_value: "High" }
          ]
        })
      end

      expect(ref.computed_properties[:template_source]).to eq('s3')
      expect(ref.computed_properties[:parameter_count]).to eq(1)
    end
  end
end
