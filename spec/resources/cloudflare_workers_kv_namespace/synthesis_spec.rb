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
require 'pangea/resources/cloudflare_workers_kv_namespace/resource'
require 'pangea/resources/cloudflare_workers_kv_namespace/types'
require 'pangea/resources/cloudflare_worker_script/resource'

RSpec.describe 'cloudflare_workers_kv_namespace synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:account_id) { "a" * 32 }

  describe 'terraform synthesis' do
    it 'synthesizes basic KV namespace' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_kv_namespace(:cache, {
          account_id: "a" * 32,
          title: "Production Cache"
        })
      end

      result = synthesizer.synthesis
      namespace = result[:resource][:cloudflare_workers_kv_namespace][:cache]

      expect(namespace).to include(
        account_id: account_id,
        title: "Production Cache"
      )
    end

    it 'synthesizes namespace with descriptive title' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_kv_namespace(:session_store, {
          account_id: "a" * 32,
          title: "User Sessions - Production"
        })
      end

      result = synthesizer.synthesis
      namespace = result[:resource][:cloudflare_workers_kv_namespace][:session_store]

      expect(namespace[:title]).to eq("User Sessions - Production")
    end

    it 'synthesizes multiple namespaces for different environments' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        cloudflare_workers_kv_namespace(:cache_prod, {
          account_id: "a" * 32,
          title: "Cache - Production"
        })

        cloudflare_workers_kv_namespace(:cache_staging, {
          account_id: "a" * 32,
          title: "Cache - Staging"
        })

        cloudflare_workers_kv_namespace(:cache_dev, {
          account_id: "a" * 32,
          title: "Cache - Development"
        })
      end

      result = synthesizer.synthesis
      namespaces = result[:resource][:cloudflare_workers_kv_namespace]

      expect(namespaces).to have_key(:cache_prod)
      expect(namespaces).to have_key(:cache_staging)
      expect(namespaces).to have_key(:cache_dev)
      expect(namespaces[:cache_prod][:title]).to eq("Cache - Production")
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_kv_namespace(:test, {
          account_id: "a" * 32,
          title: "Test Namespace"
        })
      end

      expect(ref.id).to eq("${cloudflare_workers_kv_namespace.test.id}")
      expect(ref.outputs[:namespace_id]).to eq("${cloudflare_workers_kv_namespace.test.id}")
    end

    it 'enables namespace reference in worker scripts' do
      ns_ref = nil

      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # Create namespace
        ns_ref = cloudflare_workers_kv_namespace(:cache, {
          account_id: "a" * 32,
          title: "API Cache"
        })

        # Create worker script that uses the namespace
        cloudflare_worker_script(:api, {
          account_id: "a" * 32,
          name: "api-worker",
          content: "export default { async fetch() { return new Response('OK') } }",
          kv_namespace_bindings: [
            { name: "CACHE", namespace_id: ns_ref.id }
          ]
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:cloudflare_workers_kv_namespace]).to have_key(:cache)
      expect(result[:resource][:cloudflare_worker_script]).to have_key(:api)

      worker = result[:resource][:cloudflare_worker_script][:api]
      # Bindings are always Arrays in Terraform JSON format
      expect(worker[:kv_namespace_binding]).to be_an(Array)
      expect(worker[:kv_namespace_binding].length).to eq(1)
      expect(worker[:kv_namespace_binding][0][:name]).to eq("CACHE")
      expect(worker[:kv_namespace_binding][0][:namespace_id]).to eq("${cloudflare_workers_kv_namespace.cache.id}")
    end
  end
end
