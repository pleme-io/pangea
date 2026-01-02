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
require 'pangea/resources/aws_cloudfront_origin_access_control/resource'

RSpec.describe "aws_cloudfront_origin_access_control synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_origin_access_control(:test, {
          name: "test-oac",
          origin_access_control_origin_type: "s3",
          signing_behavior: "always",
          signing_protocol: "sigv4"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_cloudfront_origin_access_control")
      expect(result["resource"]["aws_cloudfront_origin_access_control"]).to have_key("test")

      oac = result["resource"]["aws_cloudfront_origin_access_control"]["test"]
      expect(oac["name"]).to eq("test-oac")
      expect(oac["signing_behavior"]).to eq("always")
    end

    it "includes description when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_origin_access_control(:test, {
          name: "test-oac",
          description: "Test Origin Access Control",
          origin_access_control_origin_type: "s3",
          signing_behavior: "always",
          signing_protocol: "sigv4"
        })
      end

      result = synthesizer.synthesis
      oac = result["resource"]["aws_cloudfront_origin_access_control"]["test"]

      expect(oac).to have_key("description")
      expect(oac["description"]).to eq("Test Origin Access Control")
    end

    it "applies default values correctly" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_origin_access_control(:test, {
          name: "test-oac"
        })
      end

      result = synthesizer.synthesis
      oac = result["resource"]["aws_cloudfront_origin_access_control"]["test"]

      expect(oac["origin_access_control_origin_type"]).to eq("s3")
      expect(oac["signing_behavior"]).to eq("always")
      expect(oac["signing_protocol"]).to eq("sigv4")
    end

    it "supports different signing behaviors" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_origin_access_control(:test, {
          name: "test-oac-no-override",
          signing_behavior: "no-override"
        })
      end

      result = synthesizer.synthesis
      oac = result["resource"]["aws_cloudfront_origin_access_control"]["test"]

      expect(oac["signing_behavior"]).to eq("no-override")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_origin_access_control(:test, {
          name: "test-oac"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_cloudfront_origin_access_control"]).to be_a(Hash)
      expect(result["resource"]["aws_cloudfront_origin_access_control"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      oac = result["resource"]["aws_cloudfront_origin_access_control"]["test"]
      expect(oac).to have_key("name")
      expect(oac["name"]).to be_a(String)
      expect(oac).to have_key("origin_access_control_origin_type")
      expect(oac).to have_key("signing_behavior")
      expect(oac).to have_key("signing_protocol")
    end
  end

  describe "resource references" do
    it "returns resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_cloudfront_origin_access_control(:test, {
          name: "test-oac"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_cloudfront_origin_access_control.test.id}")
      expect(ref.etag).to eq("${aws_cloudfront_origin_access_control.test.etag}")
    end
  end
end
