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
require 'pangea/resources/aws_config_configuration_recorder/resource'

RSpec.describe "aws_config_configuration_recorder synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_configuration_recorder(:test, {
          name: "test-recorder",
          role_arn: "arn:aws:iam::123456789012:role/config-role"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_config_configuration_recorder")
      expect(result["resource"]["aws_config_configuration_recorder"]).to have_key("test")

      recorder_config = result["resource"]["aws_config_configuration_recorder"]["test"]
      expect(recorder_config["name"]).to eq("test-recorder")
      expect(recorder_config["role_arn"]).to eq("arn:aws:iam::123456789012:role/config-role")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_configuration_recorder(:test, {
          name: "test-recorder",
          role_arn: "arn:aws:iam::123456789012:role/config-role",
          tags: { Name: "test-recorder", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      recorder_config = result["resource"]["aws_config_configuration_recorder"]["test"]

      expect(recorder_config).to have_key("tags")
      expect(recorder_config["tags"]["Name"]).to eq("test-recorder")
      expect(recorder_config["tags"]["Environment"]).to eq("test")
    end

    it "includes recording_group configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_configuration_recorder(:test, {
          name: "test-recorder",
          role_arn: "arn:aws:iam::123456789012:role/config-role",
          recording_group: {
            all_supported: true,
            include_global_resource_types: true
          }
        })
      end

      result = synthesizer.synthesis
      recorder_config = result["resource"]["aws_config_configuration_recorder"]["test"]

      expect(recorder_config).to have_key("recording_group")
      expect(recorder_config["recording_group"]["all_supported"]).to eq(true)
      expect(recorder_config["recording_group"]["include_global_resource_types"]).to eq(true)
    end

    it "supports specific resource types in recording_group" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_configuration_recorder(:test, {
          name: "ec2-recorder",
          role_arn: "arn:aws:iam::123456789012:role/config-role",
          recording_group: {
            all_supported: false,
            include_global_resource_types: false,
            resource_types: [
              "AWS::EC2::Instance",
              "AWS::EC2::SecurityGroup"
            ]
          }
        })
      end

      result = synthesizer.synthesis
      recorder_config = result["resource"]["aws_config_configuration_recorder"]["test"]

      expect(recorder_config["recording_group"]["all_supported"]).to eq(false)
      expect(recorder_config["recording_group"]["resource_types"]).to include("AWS::EC2::Instance")
      expect(recorder_config["recording_group"]["resource_types"]).to include("AWS::EC2::SecurityGroup")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_configuration_recorder(:test, {
          name: "test-recorder",
          role_arn: "arn:aws:iam::123456789012:role/config-role"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_config_configuration_recorder"]).to be_a(Hash)
      expect(result["resource"]["aws_config_configuration_recorder"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      recorder_config = result["resource"]["aws_config_configuration_recorder"]["test"]
      expect(recorder_config).to have_key("name")
      expect(recorder_config).to have_key("role_arn")
      expect(recorder_config["name"]).to be_a(String)
      expect(recorder_config["role_arn"]).to be_a(String)
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_config_configuration_recorder(:test, {
          name: "test-recorder",
          role_arn: "arn:aws:iam::123456789012:role/config-role"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_config_configuration_recorder')
      expect(ref.name).to eq(:test)
      expect(ref.outputs).to have_key(:name)
      expect(ref.outputs).to have_key(:role_arn)
    end
  end
end
