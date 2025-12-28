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
require 'pangea/resources/aws_config_delivery_channel/resource'

RSpec.describe "aws_config_delivery_channel synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_delivery_channel(:test, {
          name: "test-channel",
          s3_bucket_name: "config-bucket"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_config_delivery_channel")
      expect(result["resource"]["aws_config_delivery_channel"]).to have_key("test")

      channel_config = result["resource"]["aws_config_delivery_channel"]["test"]
      expect(channel_config["name"]).to eq("test-channel")
      expect(channel_config["s3_bucket_name"]).to eq("config-bucket")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_delivery_channel(:test, {
          name: "test-channel",
          s3_bucket_name: "config-bucket",
          tags: { Name: "test-channel", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      channel_config = result["resource"]["aws_config_delivery_channel"]["test"]

      expect(channel_config).to have_key("tags")
      expect(channel_config["tags"]["Name"]).to eq("test-channel")
      expect(channel_config["tags"]["Environment"]).to eq("test")
    end

    it "includes s3_key_prefix when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_delivery_channel(:test, {
          name: "test-channel",
          s3_bucket_name: "config-bucket",
          s3_key_prefix: "config/"
        })
      end

      result = synthesizer.synthesis
      channel_config = result["resource"]["aws_config_delivery_channel"]["test"]

      expect(channel_config["s3_key_prefix"]).to eq("config/")
    end

    it "includes encryption configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_delivery_channel(:test, {
          name: "secure-channel",
          s3_bucket_name: "config-bucket",
          s3_kms_key_arn: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
        })
      end

      result = synthesizer.synthesis
      channel_config = result["resource"]["aws_config_delivery_channel"]["test"]

      expect(channel_config["s3_kms_key_arn"]).to eq("arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012")
    end

    it "includes SNS topic configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_delivery_channel(:test, {
          name: "test-channel",
          s3_bucket_name: "config-bucket",
          sns_topic_arn: "arn:aws:sns:us-east-1:123456789012:config-notifications"
        })
      end

      result = synthesizer.synthesis
      channel_config = result["resource"]["aws_config_delivery_channel"]["test"]

      expect(channel_config["sns_topic_arn"]).to eq("arn:aws:sns:us-east-1:123456789012:config-notifications")
    end

    it "includes snapshot_delivery_properties" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_delivery_channel(:test, {
          name: "test-channel",
          s3_bucket_name: "config-bucket",
          snapshot_delivery_properties: {
            delivery_frequency: "Six_Hours"
          }
        })
      end

      result = synthesizer.synthesis
      channel_config = result["resource"]["aws_config_delivery_channel"]["test"]

      expect(channel_config).to have_key("snapshot_delivery_properties")
      expect(channel_config["snapshot_delivery_properties"]["delivery_frequency"]).to eq("Six_Hours")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_config_delivery_channel(:test, {
          name: "test-channel",
          s3_bucket_name: "config-bucket"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_config_delivery_channel"]).to be_a(Hash)
      expect(result["resource"]["aws_config_delivery_channel"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      channel_config = result["resource"]["aws_config_delivery_channel"]["test"]
      expect(channel_config).to have_key("name")
      expect(channel_config).to have_key("s3_bucket_name")
      expect(channel_config["name"]).to be_a(String)
      expect(channel_config["s3_bucket_name"]).to be_a(String)
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_config_delivery_channel(:test, {
          name: "test-channel",
          s3_bucket_name: "config-bucket"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_config_delivery_channel')
      expect(ref.name).to eq(:test)
      expect(ref.outputs).to have_key(:id)
      expect(ref.outputs).to have_key(:name)
      expect(ref.outputs).to have_key(:s3_bucket_name)
    end
  end
end
