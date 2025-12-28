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
require 'pangea/resources/aws_cloudfront_distribution/resource'

RSpec.describe "aws_cloudfront_distribution synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_distribution(:test, {
          origin: [{
            domain_name: "example-bucket.s3.amazonaws.com",
            origin_id: "S3-example"
          }],
          default_cache_behavior: {
            target_origin_id: "S3-example",
            viewer_protocol_policy: "redirect-to-https"
          },
          comment: "Test distribution"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_cloudfront_distribution")
      expect(result["resource"]["aws_cloudfront_distribution"]).to have_key("test")

      distribution = result["resource"]["aws_cloudfront_distribution"]["test"]
      expect(distribution["comment"]).to eq("Test distribution")
      expect(distribution["enabled"]).to eq(true)
    end

    it "includes origin configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_distribution(:test, {
          origin: [{
            domain_name: "example-bucket.s3.amazonaws.com",
            origin_id: "S3-example",
            s3_origin_config: {
              origin_access_control_id: "E123456789012"
            }
          }],
          default_cache_behavior: {
            target_origin_id: "S3-example",
            viewer_protocol_policy: "https-only"
          }
        })
      end

      result = synthesizer.synthesis
      distribution = result["resource"]["aws_cloudfront_distribution"]["test"]

      expect(distribution["origin"]).to be_an(Array)
      expect(distribution["origin"].first["domain_name"]).to eq("example-bucket.s3.amazonaws.com")
      expect(distribution["origin"].first["origin_id"]).to eq("S3-example")
    end

    it "applies default values correctly" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_distribution(:test, {
          origin: [{
            domain_name: "example-bucket.s3.amazonaws.com",
            origin_id: "S3-example"
          }],
          default_cache_behavior: {
            target_origin_id: "S3-example"
          }
        })
      end

      result = synthesizer.synthesis
      distribution = result["resource"]["aws_cloudfront_distribution"]["test"]

      expect(distribution["enabled"]).to eq(true)
      expect(distribution["http_version"]).to eq("http2")
      expect(distribution["is_ipv6_enabled"]).to eq(true)
      expect(distribution["price_class"]).to eq("PriceClass_All")
    end

    it "supports custom origin configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_distribution(:test, {
          origin: [{
            domain_name: "api.example.com",
            origin_id: "custom-origin",
            custom_origin_config: {
              http_port: 80,
              https_port: 443,
              origin_protocol_policy: "https-only",
              origin_ssl_protocols: ["TLSv1.2"]
            }
          }],
          default_cache_behavior: {
            target_origin_id: "custom-origin",
            viewer_protocol_policy: "https-only"
          }
        })
      end

      result = synthesizer.synthesis
      distribution = result["resource"]["aws_cloudfront_distribution"]["test"]
      origin = distribution["origin"].first

      expect(origin["custom_origin_config"]["origin_protocol_policy"]).to eq("https-only")
      expect(origin["custom_origin_config"]["origin_ssl_protocols"]).to eq(["TLSv1.2"])
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_distribution(:test, {
          origin: [{
            domain_name: "example-bucket.s3.amazonaws.com",
            origin_id: "S3-example"
          }],
          default_cache_behavior: {
            target_origin_id: "S3-example",
            viewer_protocol_policy: "redirect-to-https"
          }
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_cloudfront_distribution"]).to be_a(Hash)
      expect(result["resource"]["aws_cloudfront_distribution"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      distribution = result["resource"]["aws_cloudfront_distribution"]["test"]
      expect(distribution).to have_key("origin")
      expect(distribution).to have_key("default_cache_behavior")
      expect(distribution).to have_key("restrictions")
      expect(distribution).to have_key("viewer_certificate")
    end
  end

  describe "resource references" do
    it "returns resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_cloudfront_distribution(:test, {
          origin: [{
            domain_name: "example-bucket.s3.amazonaws.com",
            origin_id: "S3-example"
          }],
          default_cache_behavior: {
            target_origin_id: "S3-example",
            viewer_protocol_policy: "redirect-to-https"
          }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_cloudfront_distribution.test.id}")
      expect(ref.arn).to eq("${aws_cloudfront_distribution.test.arn}")
      expect(ref.domain_name).to eq("${aws_cloudfront_distribution.test.domain_name}")
      expect(ref.hosted_zone_id).to eq("${aws_cloudfront_distribution.test.hosted_zone_id}")
    end
  end
end
