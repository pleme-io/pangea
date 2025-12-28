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

RSpec.describe "aws_config_retention_configuration synthesis" do
  include Pangea::Resources::AWS::Config

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_retention_configuration(:test, {
          retention_period_in_days: 365
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_config_retention_configuration")
      expect(result["resource"]["aws_config_retention_configuration"]).to have_key("test")

      retention_config = result["resource"]["aws_config_retention_configuration"]["test"]
      expect(retention_config["retention_period_in_days"]).to eq(365)
    end

    it "supports minimum retention period" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_retention_configuration(:test, {
          retention_period_in_days: 30
        })
      end

      result = synthesizer.synthesis
      retention_config = result["resource"]["aws_config_retention_configuration"]["test"]

      expect(retention_config["retention_period_in_days"]).to eq(30)
    end

    it "supports maximum retention period" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_retention_configuration(:test, {
          retention_period_in_days: 2557
        })
      end

      result = synthesizer.synthesis
      retention_config = result["resource"]["aws_config_retention_configuration"]["test"]

      expect(retention_config["retention_period_in_days"]).to eq(2557)
    end

    it "supports 7 year compliance retention" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_retention_configuration(:test, {
          retention_period_in_days: 2555  # ~7 years
        })
      end

      result = synthesizer.synthesis
      retention_config = result["resource"]["aws_config_retention_configuration"]["test"]

      expect(retention_config["retention_period_in_days"]).to eq(2555)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_retention_configuration(:test, {
          retention_period_in_days: 365
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_config_retention_configuration"]).to be_a(Hash)
      expect(result["resource"]["aws_config_retention_configuration"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      retention_config = result["resource"]["aws_config_retention_configuration"]["test"]
      expect(retention_config).to have_key("retention_period_in_days")
      expect(retention_config["retention_period_in_days"]).to be_a(Integer)
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        ref = aws_config_retention_configuration(:test, {
          retention_period_in_days: 365
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_config_retention_configuration')
      expect(ref.name).to eq(:test)
      expect(ref.outputs).to have_key(:id)
      expect(ref.outputs).to have_key(:arn)
    end
  end
end
