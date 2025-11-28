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
require 'pangea/resources/cloudflare_healthcheck/resource'
require 'pangea/resources/cloudflare_healthcheck/types'

RSpec.describe 'cloudflare_healthcheck synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:zone_id) { "023e105f4ecef8ad9ca31a8372d0c353" }

  describe 'terraform synthesis' do
    it 'synthesizes basic HTTPS health check' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_healthcheck(:api_health, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "api-health",
          address: "api.example.com",
          type: "HTTPS"
        })
      end

      result = synthesizer.synthesis
      hc = result[:resource][:cloudflare_healthcheck][:api_health]

      expect(hc).to include(
        zone_id: zone_id,
        name: "api-health",
        address: "api.example.com",
        type: "HTTPS"
      )
      expect(hc[:interval]).to eq(60)  # default
      expect(hc[:timeout]).to eq(5)  # default
      expect(hc[:retries]).to eq(2)  # default
    end

    it 'synthesizes HTTP health check with path and expected codes' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_healthcheck(:web_health, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "web-health",
          address: "www.example.com",
          type: "HTTP",
          path: "/health",
          method: "GET",
          expected_codes: "200",
          expected_body: "OK"
        })
      end

      result = synthesizer.synthesis
      hc = result[:resource][:cloudflare_healthcheck][:web_health]

      expect(hc[:type]).to eq("HTTP")
      expect(hc[:path]).to eq("/health")
      expect(hc[:method]).to eq("GET")
      expect(hc[:expected_codes]).to eq("200")
      expect(hc[:expected_body]).to eq("OK")
    end

    it 'synthesizes TCP health check with custom port' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_healthcheck(:db_health, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "database-health",
          address: "db.example.com",
          type: "TCP",
          port: 5432,
          interval: 120
        })
      end

      result = synthesizer.synthesis
      hc = result[:resource][:cloudflare_healthcheck][:db_health]

      expect(hc[:type]).to eq("TCP")
      expect(hc[:port]).to eq(5432)
      expect(hc[:interval]).to eq(120)
    end

    it 'synthesizes health check with notifications' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_healthcheck(:critical_health, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "critical-service",
          address: "critical.example.com",
          type: "HTTPS",
          notification_email_addresses: ["ops@example.com", "alerts@example.com"]
        })
      end

      result = synthesizer.synthesis
      hc = result[:resource][:cloudflare_healthcheck][:critical_health]

      expect(hc[:notification_email_addresses]).to eq([
        "ops@example.com",
        "alerts@example.com"
      ])
    end

    it 'synthesizes health check with consecutive fail/success thresholds' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_healthcheck(:sensitive_health, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "sensitive-check",
          address: "app.example.com",
          type: "HTTPS",
          consecutive_fails: 3,
          consecutive_successes: 2,
          interval: 30
        })
      end

      result = synthesizer.synthesis
      hc = result[:resource][:cloudflare_healthcheck][:sensitive_health]

      expect(hc[:consecutive_fails]).to eq(3)
      expect(hc[:consecutive_successes]).to eq(2)
      expect(hc[:interval]).to eq(30)
    end

    it 'synthesizes health check with specific regions' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_healthcheck(:regional_health, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "regional-check",
          address: "eu.example.com",
          type: "HTTPS",
          check_regions: ["WEU", "ENAM"]
        })
      end

      result = synthesizer.synthesis
      hc = result[:resource][:cloudflare_healthcheck][:regional_health]

      expect(hc[:check_regions]).to eq(["WEU", "ENAM"])
    end

    it 'synthesizes health check with custom timeout and retries' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_healthcheck(:slow_health, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "slow-service",
          address: "slow.example.com",
          type: "HTTPS",
          timeout: 10,
          retries: 5,
          interval: 300
        })
      end

      result = synthesizer.synthesis
      hc = result[:resource][:cloudflare_healthcheck][:slow_health]

      expect(hc[:timeout]).to eq(10)
      expect(hc[:retries]).to eq(5)
      expect(hc[:interval]).to eq(300)
    end

    it 'synthesizes multiple health checks for different services' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        cloudflare_healthcheck(:api_health, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "api",
          address: "api.example.com",
          type: "HTTPS",
          path: "/health"
        })

        cloudflare_healthcheck(:web_health, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "web",
          address: "www.example.com",
          type: "HTTP",
          path: "/status"
        })

        cloudflare_healthcheck(:db_health, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "database",
          address: "db.example.com",
          type: "TCP",
          port: 5432
        })
      end

      result = synthesizer.synthesis
      hcs = result[:resource][:cloudflare_healthcheck]

      expect(hcs).to have_key(:api_health)
      expect(hcs).to have_key(:web_health)
      expect(hcs).to have_key(:db_health)
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_healthcheck(:test, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "test-health",
          address: "test.example.com"
        })
      end

      expect(ref.id).to eq("${cloudflare_healthcheck.test.id}")
      expect(ref.outputs[:healthcheck_id]).to eq("${cloudflare_healthcheck.test.id}")
      expect(ref.outputs[:status]).to eq("${cloudflare_healthcheck.test.status}")
      expect(ref.outputs[:failure_reason]).to eq("${cloudflare_healthcheck.test.failure_reason}")
    end
  end

  describe 'resource composition' do
    it 'creates comprehensive monitoring setup' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # Public web health
        cloudflare_healthcheck(:web, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "web-public",
          address: "www.example.com",
          type: "HTTPS",
          path: "/",
          expected_codes: "200",
          interval: 60,
          notification_email_addresses: ["ops@example.com"]
        })

        # API health
        cloudflare_healthcheck(:api, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "api-service",
          address: "api.example.com",
          type: "HTTPS",
          path: "/health",
          expected_body: "healthy",
          interval: 30,
          notification_email_addresses: ["ops@example.com"]
        })

        # Database connectivity
        cloudflare_healthcheck(:db, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "db-connectivity",
          address: "db.example.com",
          type: "TCP",
          port: 5432,
          interval: 120
        })
      end

      result = synthesizer.synthesis
      hcs = result[:resource][:cloudflare_healthcheck]

      expect(hcs).to have_key(:web)
      expect(hcs).to have_key(:api)
      expect(hcs).to have_key(:db)
      expect(hcs[:api][:interval]).to eq(30)
      expect(hcs[:db][:type]).to eq("TCP")
    end
  end
end
