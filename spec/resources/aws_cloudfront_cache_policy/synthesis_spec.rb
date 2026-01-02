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
require 'pangea/resources/aws_cloudfront_cache_policy/resource'

RSpec.describe "aws_cloudfront_cache_policy synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_cache_policy(:test, {
          name: "test-cache-policy",
          default_ttl: 86400,
          max_ttl: 31536000,
          min_ttl: 0,
          parameters_in_cache_key_and_forwarded_to_origin: {
            enable_accept_encoding_brotli: true,
            enable_accept_encoding_gzip: true,
            headers_config: {
              header_behavior: "none"
            },
            query_strings_config: {
              query_string_behavior: "none"
            },
            cookies_config: {
              cookie_behavior: "none"
            }
          }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_cloudfront_cache_policy")
      expect(result["resource"]["aws_cloudfront_cache_policy"]).to have_key("test")

      policy = result["resource"]["aws_cloudfront_cache_policy"]["test"]
      expect(policy["name"]).to eq("test-cache-policy")
      expect(policy["default_ttl"]).to eq(86400)
    end

    it "includes comment when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_cache_policy(:test, {
          name: "test-cache-policy",
          comment: "Test cache policy for API responses",
          parameters_in_cache_key_and_forwarded_to_origin: {
            enable_accept_encoding_brotli: false,
            enable_accept_encoding_gzip: false,
            headers_config: {
              header_behavior: "none"
            },
            query_strings_config: {
              query_string_behavior: "none"
            },
            cookies_config: {
              cookie_behavior: "none"
            }
          }
        })
      end

      result = synthesizer.synthesis
      policy = result["resource"]["aws_cloudfront_cache_policy"]["test"]

      expect(policy).to have_key("comment")
      expect(policy["comment"]).to eq("Test cache policy for API responses")
    end

    it "applies default values correctly" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_cache_policy(:test, {
          name: "test-cache-policy",
          parameters_in_cache_key_and_forwarded_to_origin: {
            enable_accept_encoding_brotli: false,
            enable_accept_encoding_gzip: false,
            headers_config: {
              header_behavior: "none"
            },
            query_strings_config: {
              query_string_behavior: "none"
            },
            cookies_config: {
              cookie_behavior: "none"
            }
          }
        })
      end

      result = synthesizer.synthesis
      policy = result["resource"]["aws_cloudfront_cache_policy"]["test"]

      expect(policy["default_ttl"]).to eq(86400)
      expect(policy["max_ttl"]).to eq(31536000)
      expect(policy["min_ttl"]).to eq(0)
    end

    it "supports header whitelisting" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_cache_policy(:test, {
          name: "test-cache-policy-headers",
          parameters_in_cache_key_and_forwarded_to_origin: {
            enable_accept_encoding_brotli: true,
            enable_accept_encoding_gzip: true,
            headers_config: {
              header_behavior: "whitelist",
              headers: {
                items: ["Authorization", "Accept-Language"]
              }
            },
            query_strings_config: {
              query_string_behavior: "none"
            },
            cookies_config: {
              cookie_behavior: "none"
            }
          }
        })
      end

      result = synthesizer.synthesis
      policy = result["resource"]["aws_cloudfront_cache_policy"]["test"]

      expect(policy["parameters_in_cache_key_and_forwarded_to_origin"]["headers_config"]["header_behavior"]).to eq("whitelist")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cloudfront_cache_policy(:test, {
          name: "test-cache-policy",
          parameters_in_cache_key_and_forwarded_to_origin: {
            enable_accept_encoding_brotli: false,
            enable_accept_encoding_gzip: false,
            headers_config: {
              header_behavior: "none"
            },
            query_strings_config: {
              query_string_behavior: "none"
            },
            cookies_config: {
              cookie_behavior: "none"
            }
          }
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_cloudfront_cache_policy"]).to be_a(Hash)
      expect(result["resource"]["aws_cloudfront_cache_policy"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      policy = result["resource"]["aws_cloudfront_cache_policy"]["test"]
      expect(policy).to have_key("name")
      expect(policy["name"]).to be_a(String)
      expect(policy).to have_key("default_ttl")
      expect(policy).to have_key("max_ttl")
      expect(policy).to have_key("min_ttl")
      expect(policy).to have_key("parameters_in_cache_key_and_forwarded_to_origin")
    end
  end

  describe "resource references" do
    it "returns resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_cloudfront_cache_policy(:test, {
          name: "test-cache-policy",
          parameters_in_cache_key_and_forwarded_to_origin: {
            enable_accept_encoding_brotli: false,
            enable_accept_encoding_gzip: false,
            headers_config: {
              header_behavior: "none"
            },
            query_strings_config: {
              query_string_behavior: "none"
            },
            cookies_config: {
              cookie_behavior: "none"
            }
          }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.id).to eq("${aws_cloudfront_cache_policy.test.id}")
      expect(ref.etag).to eq("${aws_cloudfront_cache_policy.test.etag}")
    end
  end
end
