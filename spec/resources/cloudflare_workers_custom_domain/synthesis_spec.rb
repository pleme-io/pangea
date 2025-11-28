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
require 'pangea/resources/cloudflare_workers_custom_domain/resource'
require 'pangea/resources/cloudflare_workers_custom_domain/types'

RSpec.describe 'cloudflare_workers_custom_domain synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:account_id) { "a" * 32 }
  let(:zone_id) { "023e105f4ecef8ad9ca31a8372d0c353" }

  describe 'terraform synthesis' do
    it 'synthesizes production custom domain' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_custom_domain(:api_domain, {
          account_id: "a" * 32,
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "api.example.com",
          service: "api-worker",
          environment: "production"
        })
      end

      result = synthesizer.synthesis
      domain = result[:resource][:cloudflare_workers_custom_domain][:api_domain]

      expect(domain).to include(
        account_id: account_id,
        zone_id: zone_id,
        hostname: "api.example.com",
        service: "api-worker",
        environment: "production"
      )
    end

    it 'synthesizes staging environment domain' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_custom_domain(:staging, {
          account_id: "a" * 32,
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "staging.example.com",
          service: "api-worker",
          environment: "staging"
        })
      end

      result = synthesizer.synthesis
      domain = result[:resource][:cloudflare_workers_custom_domain][:staging]

      expect(domain[:environment]).to eq("staging")
    end

    it 'synthesizes development environment domain' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_custom_domain(:dev, {
          account_id: "a" * 32,
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "dev.example.com",
          service: "api-worker",
          environment: "development"
        })
      end

      result = synthesizer.synthesis
      domain = result[:resource][:cloudflare_workers_custom_domain][:dev]

      expect(domain[:environment]).to eq("development")
    end

    it 'synthesizes multiple custom domains for different services' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        cloudflare_workers_custom_domain(:api, {
          account_id: "a" * 32,
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "api.example.com",
          service: "api-worker"
        })

        cloudflare_workers_custom_domain(:admin, {
          account_id: "a" * 32,
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "admin.example.com",
          service: "admin-worker"
        })

        cloudflare_workers_custom_domain(:webhooks, {
          account_id: "a" * 32,
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "webhooks.example.com",
          service: "webhook-worker"
        })
      end

      result = synthesizer.synthesis
      domains = result[:resource][:cloudflare_workers_custom_domain]

      expect(domains).to have_key(:api)
      expect(domains).to have_key(:admin)
      expect(domains).to have_key(:webhooks)
    end
  end

  describe 'resource composition' do
    it 'creates worker with custom domain' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # Create worker
        cloudflare_worker_script(:api, {
          account_id: "a" * 32,
          name: "api-worker",
          content: "export default { async fetch() { return new Response('OK') } }"
        })

        # Attach custom domain
        cloudflare_workers_custom_domain(:api_domain, {
          account_id: "a" * 32,
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "api.example.com",
          service: "api-worker",
          environment: "production"
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:cloudflare_worker_script]).to have_key(:api)
      expect(result[:resource][:cloudflare_workers_custom_domain]).to have_key(:api_domain)
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_custom_domain(:test, {
          account_id: "a" * 32,
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          hostname: "test.example.com",
          service: "test-worker"
        })
      end

      expect(ref.id).to eq("${cloudflare_workers_custom_domain.test.id}")
      expect(ref.outputs[:domain_id]).to eq("${cloudflare_workers_custom_domain.test.id}")
      expect(ref.outputs[:zone_name]).to eq("${cloudflare_workers_custom_domain.test.zone_name}")
    end
  end
end
