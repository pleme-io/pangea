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

RSpec.describe "aws_config_aggregate_authorization synthesis" do
  include Pangea::Resources::AWS::Config

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_aggregate_authorization(:test, {
          account_id: "123456789012",
          region: "us-east-1"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_config_aggregate_authorization")
      expect(result["resource"]["aws_config_aggregate_authorization"]).to have_key("test")

      auth_config = result["resource"]["aws_config_aggregate_authorization"]["test"]
      expect(auth_config["account_id"]).to eq("123456789012")
      expect(auth_config["region"]).to eq("us-east-1")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_aggregate_authorization(:test, {
          account_id: "123456789012",
          region: "us-east-1",
          tags: { Name: "test-authorization", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      auth_config = result["resource"]["aws_config_aggregate_authorization"]["test"]

      expect(auth_config).to have_key("tags")
      expect(auth_config["tags"]["Name"]).to eq("test-authorization")
      expect(auth_config["tags"]["Environment"]).to eq("test")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_aggregate_authorization(:test, {
          account_id: "123456789012",
          region: "us-east-1"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_config_aggregate_authorization"]).to be_a(Hash)
      expect(result["resource"]["aws_config_aggregate_authorization"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      auth_config = result["resource"]["aws_config_aggregate_authorization"]["test"]
      expect(auth_config).to have_key("account_id")
      expect(auth_config).to have_key("region")
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        ref = aws_config_aggregate_authorization(:test, {
          account_id: "123456789012",
          region: "us-east-1"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_config_aggregate_authorization')
      expect(ref.name).to eq(:test)
      expect(ref.outputs).to have_key(:id)
      expect(ref.outputs).to have_key(:arn)
    end
  end
end
