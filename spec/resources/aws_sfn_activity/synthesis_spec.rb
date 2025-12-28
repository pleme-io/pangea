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
require 'pangea/resources/aws_sfn_activity/resource'

RSpec.describe "aws_sfn_activity synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for a basic activity" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sfn_activity(:test_activity, {
          name: "test-activity"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_sfn_activity")
      expect(result["resource"]["aws_sfn_activity"]).to have_key("test_activity")

      config = result["resource"]["aws_sfn_activity"]["test_activity"]
      expect(config["name"]).to eq("test-activity")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sfn_activity(:tagged_activity, {
          name: "tagged-activity",
          tags: { Name: "tagged-activity", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_sfn_activity"]["tagged_activity"]

      expect(config).to have_key("tags")
      expect(config["tags"]["Name"]).to eq("tagged-activity")
      expect(config["tags"]["Environment"]).to eq("test")
    end

    it "supports data processing activity naming pattern" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sfn_activity(:data_processor, {
          name: "data-processing-activity"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_sfn_activity"]["data_processor"]

      expect(config["name"]).to eq("data-processing-activity")
    end

    it "supports worker activity naming pattern" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sfn_activity(:worker, {
          name: "batch-worker-activity"
        })
      end

      result = synthesizer.synthesis
      config = result["resource"]["aws_sfn_activity"]["worker"]

      expect(config["name"]).to eq("batch-worker-activity")
    end
  end

  describe "resource reference" do
    it "returns a reference with expected outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_sfn_activity(:ref_test, {
          name: "reference-test-activity"
        })
      end

      expect(ref).not_to be_nil
      expect(ref.type).to eq('aws_sfn_activity')
      expect(ref.name).to eq(:ref_test)
      expect(ref.outputs[:arn]).to eq("${aws_sfn_activity.ref_test.arn}")
      expect(ref.outputs[:id]).to eq("${aws_sfn_activity.ref_test.id}")
      expect(ref.outputs[:name]).to eq("${aws_sfn_activity.ref_test.name}")
      expect(ref.outputs[:creation_date]).to eq("${aws_sfn_activity.ref_test.creation_date}")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_sfn_activity(:validation_test, {
          name: "validation-test-activity"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_sfn_activity"]).to be_a(Hash)
      expect(result["resource"]["aws_sfn_activity"]["validation_test"]).to be_a(Hash)

      # Validate required attributes are present
      config = result["resource"]["aws_sfn_activity"]["validation_test"]
      expect(config).to have_key("name")
      expect(config["name"]).to be_a(String)
    end
  end
end
