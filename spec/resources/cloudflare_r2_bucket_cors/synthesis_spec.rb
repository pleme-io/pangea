# frozen_string_literal: true
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
require 'pangea/resources/cloudflare_r2_bucket_cors/resource'
require 'pangea/resources/cloudflare_r2_bucket_cors/types'

RSpec.describe 'cloudflare_r2_bucket_cors synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:account_id) { "a" * 32 }

  describe 'basic CORS configurations' do
    it 'synthesizes minimal CORS rule' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket_cors(:basic, {
          account_id: "a" * 32,
          bucket_name: "my-bucket",
          rules: [{
            allowed: {
              origins: ["https://example.com"],
              methods: ["GET"]
            }
          }]
        })
      end

      result = synthesizer.synthesis
      cors = result[:resource][:cloudflare_r2_bucket_cors][:basic]

      expect(cors[:account_id]).to eq(account_id)
      expect(cors[:bucket_name]).to eq("my-bucket")
      expect(cors[:rules]).to be_an(Array)
      expect(cors[:rules].first[:allowed][:origins]).to eq(["https://example.com"])
      expect(cors[:rules].first[:allowed][:methods]).to eq(["GET"])
    end

    it 'synthesizes with multiple HTTP methods' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket_cors(:multi_methods, {
          account_id: "a" * 32,
          bucket_name: "api-bucket",
          rules: [{
            allowed: {
              origins: ["https://app.example.com"],
              methods: ["GET", "POST", "PUT", "DELETE"]
            }
          }]
        })
      end

      result = synthesizer.synthesis
      cors = result[:resource][:cloudflare_r2_bucket_cors][:multi_methods]

      methods = cors[:rules].first[:allowed][:methods]
      expect(methods).to include("GET", "POST", "PUT", "DELETE")
    end

    it 'synthesizes with custom headers' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket_cors(:with_headers, {
          account_id: "a" * 32,
          bucket_name: "my-bucket",
          rules: [{
            allowed: {
              origins: ["https://app.example.com"],
              methods: ["GET", "POST"],
              headers: ["Content-Type", "Authorization"]
            }
          }]
        })
      end

      result = synthesizer.synthesis
      cors = result[:resource][:cloudflare_r2_bucket_cors][:with_headers]

      headers = cors[:rules].first[:allowed][:headers]
      expect(headers).to include("Content-Type", "Authorization")
    end
  end

  describe 'wildcard configurations' do
    it 'synthesizes with wildcard origin' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket_cors(:wildcard_origin, {
          account_id: "a" * 32,
          bucket_name: "public-bucket",
          rules: [{
            allowed: {
              origins: ["*"],
              methods: ["GET"]
            }
          }]
        })
      end

      result = synthesizer.synthesis
      cors = result[:resource][:cloudflare_r2_bucket_cors][:wildcard_origin]

      expect(cors[:rules].first[:allowed][:origins]).to eq(["*"])
    end

    it 'synthesizes with wildcard headers' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket_cors(:wildcard_headers, {
          account_id: "a" * 32,
          bucket_name: "my-bucket",
          rules: [{
            allowed: {
              origins: ["https://example.com"],
              methods: ["GET"],
              headers: ["*"]
            }
          }]
        })
      end

      result = synthesizer.synthesis
      cors = result[:resource][:cloudflare_r2_bucket_cors][:wildcard_headers]

      expect(cors[:rules].first[:allowed][:headers]).to eq(["*"])
    end

    it 'synthesizes fully open CORS' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket_cors(:fully_open, {
          account_id: "a" * 32,
          bucket_name: "public-assets",
          rules: [{
            allowed: {
              origins: ["*"],
              methods: ["GET", "HEAD"],
              headers: ["*"]
            },
            max_age_seconds: 86400
          }]
        })
      end

      result = synthesizer.synthesis
      cors = result[:resource][:cloudflare_r2_bucket_cors][:fully_open]

      rule = cors[:rules].first
      expect(rule[:allowed][:origins]).to eq(["*"])
      expect(rule[:allowed][:headers]).to eq(["*"])
      expect(rule[:max_age_seconds]).to eq(86400)
    end
  end

  describe 'preflight caching' do
    it 'synthesizes with max_age_seconds' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket_cors(:with_preflight, {
          account_id: "a" * 32,
          bucket_name: "my-bucket",
          rules: [{
            allowed: {
              origins: ["https://app.example.com"],
              methods: ["GET", "POST"]
            },
            max_age_seconds: 3600
          }]
        })
      end

      result = synthesizer.synthesis
      cors = result[:resource][:cloudflare_r2_bucket_cors][:with_preflight]

      expect(cors[:rules].first[:max_age_seconds]).to eq(3600)
    end

    it 'synthesizes with maximum max_age_seconds' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket_cors(:max_cache, {
          account_id: "a" * 32,
          bucket_name: "my-bucket",
          rules: [{
            allowed: {
              origins: ["https://example.com"],
              methods: ["GET"]
            },
            max_age_seconds: 86400
          }]
        })
      end

      result = synthesizer.synthesis
      cors = result[:resource][:cloudflare_r2_bucket_cors][:max_cache]

      expect(cors[:rules].first[:max_age_seconds]).to eq(86400)
    end
  end

  describe 'exposed headers' do
    it 'synthesizes with expose_headers' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket_cors(:with_expose, {
          account_id: "a" * 32,
          bucket_name: "my-bucket",
          rules: [{
            allowed: {
              origins: ["https://app.example.com"],
              methods: ["GET"]
            },
            expose_headers: ["ETag", "Content-Length", "Content-Type"]
          }]
        })
      end

      result = synthesizer.synthesis
      cors = result[:resource][:cloudflare_r2_bucket_cors][:with_expose]

      expose_headers = cors[:rules].first[:expose_headers]
      expect(expose_headers).to include("ETag", "Content-Length", "Content-Type")
    end
  end

  describe 'rule identifiers' do
    it 'synthesizes with rule ID' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket_cors(:with_id, {
          account_id: "a" * 32,
          bucket_name: "my-bucket",
          rules: [{
            id: "production-cors",
            allowed: {
              origins: ["https://app.example.com"],
              methods: ["GET"]
            }
          }]
        })
      end

      result = synthesizer.synthesis
      cors = result[:resource][:cloudflare_r2_bucket_cors][:with_id]

      expect(cors[:rules].first[:id]).to eq("production-cors")
    end
  end

  describe 'multiple CORS rules' do
    it 'synthesizes with multiple rules' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket_cors(:multi_rules, {
          account_id: "a" * 32,
          bucket_name: "multi-origin",
          rules: [
            {
              id: "production",
              allowed: {
                origins: ["https://app.example.com"],
                methods: ["GET", "POST", "PUT"],
                headers: ["Content-Type"]
              },
              max_age_seconds: 3600
            },
            {
              id: "staging",
              allowed: {
                origins: ["https://staging.example.com"],
                methods: ["GET"]
              },
              max_age_seconds: 1800
            }
          ]
        })
      end

      result = synthesizer.synthesis
      cors = result[:resource][:cloudflare_r2_bucket_cors][:multi_rules]

      expect(cors[:rules].length).to eq(2)
      expect(cors[:rules][0][:id]).to eq("production")
      expect(cors[:rules][1][:id]).to eq("staging")
      expect(cors[:rules][0][:max_age_seconds]).to eq(3600)
      expect(cors[:rules][1][:max_age_seconds]).to eq(1800)
    end

    it 'synthesizes with different origins per rule' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket_cors(:different_origins, {
          account_id: "a" * 32,
          bucket_name: "my-bucket",
          rules: [
            {
              allowed: {
                origins: ["https://app1.example.com"],
                methods: ["GET"]
              }
            },
            {
              allowed: {
                origins: ["https://app2.example.com", "https://app3.example.com"],
                methods: ["GET", "POST"]
              }
            }
          ]
        })
      end

      result = synthesizer.synthesis
      cors = result[:resource][:cloudflare_r2_bucket_cors][:different_origins]

      expect(cors[:rules][0][:allowed][:origins]).to eq(["https://app1.example.com"])
      expect(cors[:rules][1][:allowed][:origins]).to include("https://app2.example.com", "https://app3.example.com")
    end
  end

  describe 'multiple origins in single rule' do
    it 'synthesizes with multiple origins' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket_cors(:multi_origins, {
          account_id: "a" * 32,
          bucket_name: "my-bucket",
          rules: [{
            allowed: {
              origins: ["https://app.example.com", "https://www.example.com", "https://admin.example.com"],
              methods: ["GET"]
            }
          }]
        })
      end

      result = synthesizer.synthesis
      cors = result[:resource][:cloudflare_r2_bucket_cors][:multi_origins]

      origins = cors[:rules].first[:allowed][:origins]
      expect(origins.length).to eq(3)
      expect(origins).to include("https://app.example.com", "https://www.example.com", "https://admin.example.com")
    end
  end

  describe 'HTTP methods' do
    it 'synthesizes with all standard methods' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket_cors(:all_methods, {
          account_id: "a" * 32,
          bucket_name: "my-bucket",
          rules: [{
            allowed: {
              origins: ["https://app.example.com"],
              methods: ["GET", "HEAD", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
            }
          }]
        })
      end

      result = synthesizer.synthesis
      cors = result[:resource][:cloudflare_r2_bucket_cors][:all_methods]

      methods = cors[:rules].first[:allowed][:methods]
      expect(methods).to include("GET", "HEAD", "POST", "PUT", "DELETE", "PATCH", "OPTIONS")
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_r2_bucket_cors(:test, {
          account_id: "a" * 32,
          bucket_name: "test-bucket",
          rules: [{
            allowed: {
              origins: ["https://example.com"],
              methods: ["GET"]
            }
          }]
        })
      end

      expect(ref.id).to eq("${cloudflare_r2_bucket_cors.test.id}")
    end
  end

  describe 'validation' do
    it 'requires at least one origin' do
      expect {
        Pangea::Resources::Cloudflare::Types::R2BucketCorsAttributes.new(
          account_id: account_id,
          bucket_name: "my-bucket",
          rules: [{
            allowed: {
              origins: [],
              methods: ["GET"]
            }
          }]
        )
      }.to raise_error(Dry::Struct::Error)
    end

    it 'requires at least one method' do
      expect {
        Pangea::Resources::Cloudflare::Types::R2BucketCorsAttributes.new(
          account_id: account_id,
          bucket_name: "my-bucket",
          rules: [{
            allowed: {
              origins: ["https://example.com"],
              methods: []
            }
          }]
        )
      }.to raise_error(Dry::Struct::Error)
    end

    it 'requires at least one rule' do
      expect {
        Pangea::Resources::Cloudflare::Types::R2BucketCorsAttributes.new(
          account_id: account_id,
          bucket_name: "my-bucket",
          rules: []
        )
      }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects invalid HTTP method' do
      expect {
        Pangea::Resources::Cloudflare::Types::R2BucketCorsAttributes.new(
          account_id: account_id,
          bucket_name: "my-bucket",
          rules: [{
            allowed: {
              origins: ["https://example.com"],
              methods: ["INVALID"]
            }
          }]
        )
      }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects max_age_seconds above limit' do
      expect {
        Pangea::Resources::Cloudflare::Types::R2BucketCorsAttributes.new(
          account_id: account_id,
          bucket_name: "my-bucket",
          rules: [{
            allowed: {
              origins: ["https://example.com"],
              methods: ["GET"]
            },
            max_age_seconds: 86401  # Over 24 hours
          }]
        )
      }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects negative max_age_seconds' do
      expect {
        Pangea::Resources::Cloudflare::Types::R2BucketCorsAttributes.new(
          account_id: account_id,
          bucket_name: "my-bucket",
          rules: [{
            allowed: {
              origins: ["https://example.com"],
              methods: ["GET"]
            },
            max_age_seconds: -1
          }]
        )
      }.to raise_error(Dry::Struct::Error)
    end
  end

  describe 'helper methods' do
    it 'identifies wildcard origin' do
      attrs = Pangea::Resources::Cloudflare::Types::R2BucketCorsAttributes.new(
        account_id: account_id,
        bucket_name: "my-bucket",
        rules: [{
          allowed: {
            origins: ["*"],
            methods: ["GET"]
          }
        }]
      )

      expect(attrs.has_wildcard_origin?).to be true
    end

    it 'identifies GET allowed' do
      attrs = Pangea::Resources::Cloudflare::Types::R2BucketCorsAttributes.new(
        account_id: account_id,
        bucket_name: "my-bucket",
        rules: [{
          allowed: {
            origins: ["https://example.com"],
            methods: ["GET", "POST"]
          }
        }]
      )

      expect(attrs.allows_get?).to be true
    end

    it 'identifies multiple rules' do
      attrs = Pangea::Resources::Cloudflare::Types::R2BucketCorsAttributes.new(
        account_id: account_id,
        bucket_name: "my-bucket",
        rules: [
          {
            allowed: {
              origins: ["https://app1.example.com"],
              methods: ["GET"]
            }
          },
          {
            allowed: {
              origins: ["https://app2.example.com"],
              methods: ["POST"]
            }
          }
        ]
      )

      expect(attrs.multiple_rules?).to be true
    end

    it 'gets all unique origins' do
      attrs = Pangea::Resources::Cloudflare::Types::R2BucketCorsAttributes.new(
        account_id: account_id,
        bucket_name: "my-bucket",
        rules: [
          {
            allowed: {
              origins: ["https://app1.example.com", "https://app2.example.com"],
              methods: ["GET"]
            }
          },
          {
            allowed: {
              origins: ["https://app2.example.com", "https://app3.example.com"],
              methods: ["POST"]
            }
          }
        ]
      )

      origins = attrs.all_origins
      expect(origins.uniq.length).to eq(origins.length)  # All unique
      expect(origins).to include("https://app1.example.com", "https://app2.example.com", "https://app3.example.com")
    end

    it 'gets all unique methods' do
      attrs = Pangea::Resources::Cloudflare::Types::R2BucketCorsAttributes.new(
        account_id: account_id,
        bucket_name: "my-bucket",
        rules: [
          {
            allowed: {
              origins: ["https://example.com"],
              methods: ["GET", "POST"]
            }
          },
          {
            allowed: {
              origins: ["https://example.com"],
              methods: ["POST", "PUT"]
            }
          }
        ]
      )

      methods = attrs.all_methods
      expect(methods).to include("GET", "POST", "PUT")
    end

    it 'identifies preflight caching' do
      rule = Pangea::Resources::Cloudflare::Types::R2CorsRule.new(
        allowed: {
          origins: ["https://example.com"],
          methods: ["GET"]
        },
        max_age_seconds: 3600
      )

      expect(rule.has_preflight_caching?).to be true
    end

    it 'identifies exposed headers' do
      rule = Pangea::Resources::Cloudflare::Types::R2CorsRule.new(
        allowed: {
          origins: ["https://example.com"],
          methods: ["GET"]
        },
        expose_headers: ["ETag", "Content-Length"]
      )

      expect(rule.exposes_headers?).to be true
    end

    it 'identifies wildcard headers in allowed' do
      allowed = Pangea::Resources::Cloudflare::Types::R2CorsAllowed.new(
        origins: ["https://example.com"],
        methods: ["GET"],
        headers: ["*"]
      )

      expect(allowed.wildcard_headers?).to be true
    end

    it 'identifies GET and POST methods' do
      rule = Pangea::Resources::Cloudflare::Types::R2CorsRule.new(
        allowed: {
          origins: ["https://example.com"],
          methods: ["GET", "POST"]
        }
      )

      expect(rule.allows_get?).to be true
      expect(rule.allows_post?).to be true
    end
  end
end
