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

RSpec.describe "aws_config_configuration_aggregator_organization synthesis" do
  include Pangea::Resources::AWS::Config

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_configuration_aggregator_organization(:test, {
          name: "organization-aggregator",
          role_arn: "arn:aws:iam::123456789012:role/config-aggregator-role"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_config_configuration_aggregator_organization")
      expect(result["resource"]["aws_config_configuration_aggregator_organization"]).to have_key("test")

      aggregator_config = result["resource"]["aws_config_configuration_aggregator_organization"]["test"]
      expect(aggregator_config["name"]).to eq("organization-aggregator")
      expect(aggregator_config["role_arn"]).to eq("arn:aws:iam::123456789012:role/config-aggregator-role")
    end

    it "includes all_regions configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_configuration_aggregator_organization(:test, {
          name: "organization-aggregator",
          role_arn: "arn:aws:iam::123456789012:role/config-aggregator-role",
          all_regions: true
        })
      end

      result = synthesizer.synthesis
      aggregator_config = result["resource"]["aws_config_configuration_aggregator_organization"]["test"]

      expect(aggregator_config["all_regions"]).to eq(true)
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_configuration_aggregator_organization(:test, {
          name: "organization-aggregator",
          role_arn: "arn:aws:iam::123456789012:role/config-aggregator-role",
          tags: { Name: "test-aggregator", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      aggregator_config = result["resource"]["aws_config_configuration_aggregator_organization"]["test"]

      expect(aggregator_config).to have_key("tags")
      expect(aggregator_config["tags"]["Name"]).to eq("test-aggregator")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_configuration_aggregator_organization(:test, {
          name: "organization-aggregator",
          role_arn: "arn:aws:iam::123456789012:role/config-aggregator-role"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_config_configuration_aggregator_organization"]).to be_a(Hash)
      expect(result["resource"]["aws_config_configuration_aggregator_organization"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      aggregator_config = result["resource"]["aws_config_configuration_aggregator_organization"]["test"]
      expect(aggregator_config).to have_key("name")
      expect(aggregator_config).to have_key("role_arn")
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        ref = aws_config_configuration_aggregator_organization(:test, {
          name: "organization-aggregator",
          role_arn: "arn:aws:iam::123456789012:role/config-aggregator-role"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_config_configuration_aggregator_organization')
      expect(ref.name).to eq(:test)
      expect(ref.outputs).to have_key(:id)
      expect(ref.outputs).to have_key(:arn)
    end
  end
end
