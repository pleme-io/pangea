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
require 'pangea/resources/cloudflare_workers_kv/resource'
require 'pangea/resources/cloudflare_workers_kv/types'
require 'json'

RSpec.describe 'cloudflare_workers_kv synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:account_id) { "a" * 32 }
  let(:namespace_id) { "0" * 32 }

  describe 'terraform synthesis' do
    it 'synthesizes basic KV pair' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_kv(:config, {
          account_id: "a" * 32,
          namespace_id: "0" * 32,
          key_name: "api-url",
          value: "https://api.example.com"
        })
      end

      result = synthesizer.synthesis
      kv = result[:resource][:cloudflare_workers_kv][:config]

      expect(kv).to include(
        account_id: account_id,
        namespace_id: namespace_id,
        key: "api-url",
        value: "https://api.example.com"
      )
      expect(kv).not_to have_key(:metadata)
    end

    it 'synthesizes KV pair with JSON value' do
      json_config = JSON.dump({
        endpoint: "https://api.example.com",
        timeout: 5000,
        retry: true
      })

      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_kv(:api_config, {
          account_id: "a" * 32,
          namespace_id: "0" * 32,
          key_name: "config:api",
          value: json_config
        })
      end

      result = synthesizer.synthesis
      kv = result[:resource][:cloudflare_workers_kv][:api_config]

      expect(kv[:key]).to eq("config:api")
      expect(kv[:value]).to eq(json_config)

      # Verify value is valid JSON
      parsed = JSON.parse(kv[:value])
      expect(parsed["endpoint"]).to eq("https://api.example.com")
    end

    it 'synthesizes KV pair with metadata' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_kv(:user_data, {
          account_id: "a" * 32,
          namespace_id: "0" * 32,
          key_name: "user:12345:profile",
          value: JSON.dump({ name: "Alice", role: "admin" }),
          metadata: { user_id: "12345", last_updated: "2025-01-15" }
        })
      end

      result = synthesizer.synthesis
      kv = result[:resource][:cloudflare_workers_kv][:user_data]

      expect(kv[:metadata]).to include(
        user_id: "12345",
        last_updated: "2025-01-15"
      )
    end

    it 'synthesizes multiple KV pairs in same namespace' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        cloudflare_workers_kv(:key1, {
          account_id: "a" * 32,
          namespace_id: "0" * 32,
          key_name: "setting:theme",
          value: "dark"
        })

        cloudflare_workers_kv(:key2, {
          account_id: "a" * 32,
          namespace_id: "0" * 32,
          key_name: "setting:language",
          value: "en"
        })

        cloudflare_workers_kv(:key3, {
          account_id: "a" * 32,
          namespace_id: "0" * 32,
          key_name: "setting:timezone",
          value: "UTC"
        })
      end

      result = synthesizer.synthesis
      kv_pairs = result[:resource][:cloudflare_workers_kv]

      expect(kv_pairs).to have_key(:key1)
      expect(kv_pairs).to have_key(:key2)
      expect(kv_pairs).to have_key(:key3)
      expect(kv_pairs[:key1][:value]).to eq("dark")
      expect(kv_pairs[:key2][:value]).to eq("en")
      expect(kv_pairs[:key3][:value]).to eq("UTC")
    end
  end

  describe 'resource composition' do
    it 'creates namespace and KV pairs together' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # Create namespace
        ns = cloudflare_workers_kv_namespace(:settings, {
          account_id: "a" * 32,
          title: "Application Settings"
        })

        # Create KV pairs in that namespace
        cloudflare_workers_kv(:theme, {
          account_id: "a" * 32,
          namespace_id: ns.id,
          key_name: "theme",
          value: "dark"
        })

        cloudflare_workers_kv(:api_key, {
          account_id: "a" * 32,
          namespace_id: ns.id,
          key_name: "api-key",
          value: "secret-key-here"
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:cloudflare_workers_kv_namespace]).to have_key(:settings)
      expect(result[:resource][:cloudflare_workers_kv]).to have_key(:theme)
      expect(result[:resource][:cloudflare_workers_kv]).to have_key(:api_key)

      # Verify namespace reference
      theme_kv = result[:resource][:cloudflare_workers_kv][:theme]
      expect(theme_kv[:namespace_id]).to eq("${cloudflare_workers_kv_namespace.settings.id}")
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_kv(:test, {
          account_id: "a" * 32,
          namespace_id: "0" * 32,
          key_name: "test-key",
          value: "test-value"
        })
      end

      expect(ref.id).to eq("${cloudflare_workers_kv.test.id}")
      expect(ref.outputs[:key]).to eq("${cloudflare_workers_kv.test.key}")
      expect(ref.outputs[:value]).to eq("${cloudflare_workers_kv.test.value}")
    end
  end
end
