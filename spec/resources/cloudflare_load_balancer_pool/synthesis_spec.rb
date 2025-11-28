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
require 'pangea/resources/cloudflare_load_balancer_pool/resource'
require 'pangea/resources/cloudflare_load_balancer_pool/types'

RSpec.describe 'cloudflare_load_balancer_pool synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:account_id) { "a" * 32 }

  describe 'terraform synthesis' do
    it 'synthesizes basic pool with two origins' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_load_balancer_pool(:web_pool, {
          account_id: "a" * 32,
          name: "web-servers",
          origins: [
            { name: "server1", address: "192.0.2.1", enabled: true },
            { name: "server2", address: "192.0.2.2", enabled: true }
          ]
        })
      end

      result = synthesizer.synthesis
      pool = result[:resource][:cloudflare_load_balancer_pool][:web_pool]

      expect(pool[:account_id]).to eq(account_id)
      expect(pool[:name]).to eq("web-servers")
      expect(pool[:enabled]).to be true
      expect(pool[:minimum_origins]).to eq(1)
      expect(pool[:origin]).to be_an(Array)
      expect(pool[:origin].length).to eq(2)
    end

    it 'synthesizes pool with health monitor' do
      monitor_id = "monitor-#{SecureRandom.hex(8)}"

      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_load_balancer_pool(:monitored_pool, {
          account_id: "a" * 32,
          name: "monitored-servers",
          origins: [
            { name: "server1", address: "192.0.2.1" }
          ],
          monitor: monitor_id,
          minimum_origins: 1,
          notification_email: "ops@example.com"
        })
      end

      result = synthesizer.synthesis
      pool = result[:resource][:cloudflare_load_balancer_pool][:monitored_pool]

      expect(pool[:monitor]).to eq(monitor_id)
      expect(pool[:notification_email]).to eq("ops@example.com")
    end

    it 'synthesizes pool with regional health checks' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_load_balancer_pool(:global_pool, {
          account_id: "a" * 32,
          name: "global-origins",
          origins: [
            { name: "us-east", address: "192.0.2.1" },
            { name: "eu-west", address: "192.0.2.2" },
            { name: "ap-southeast", address: "192.0.2.3" }
          ],
          check_regions: ["WNAM", "WEU", "SEAS"],
          description: "Global pool with regional health checks"
        })
      end

      result = synthesizer.synthesis
      pool = result[:resource][:cloudflare_load_balancer_pool][:global_pool]

      expect(pool[:check_regions]).to contain_exactly("WNAM", "WEU", "SEAS")
      expect(pool[:description]).to eq("Global pool with regional health checks")
    end

    it 'synthesizes pool with weighted origins' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_load_balancer_pool(:weighted_pool, {
          account_id: "a" * 32,
          name: "weighted-servers",
          origins: [
            { name: "primary", address: "192.0.2.1", enabled: true, weight: 0.7 },
            { name: "backup", address: "192.0.2.2", enabled: true, weight: 0.3 }
          ]
        })
      end

      result = synthesizer.synthesis
      pool = result[:resource][:cloudflare_load_balancer_pool][:weighted_pool]

      origins = pool[:origin]
      expect(origins[0][:weight]).to eq(0.7)
      expect(origins[1][:weight]).to eq(0.3)
    end
  end

  describe 'resource composition' do
    it 'creates load balancer with pool and monitor' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # Create monitor
        monitor = cloudflare_load_balancer_monitor(:http_monitor, {
          account_id: "a" * 32,
          type: "http",
          method: "GET",
          expected_codes: "2xx",
          path: "/health",
          interval: 60
        })

        # Create pool using monitor
        pool = cloudflare_load_balancer_pool(:web_pool, {
          account_id: "a" * 32,
          name: "web-servers",
          origins: [
            { name: "server1", address: "192.0.2.1" }
          ],
          monitor: monitor.id
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:cloudflare_load_balancer_monitor]).to have_key(:http_monitor)
      expect(result[:resource][:cloudflare_load_balancer_pool]).to have_key(:web_pool)

      pool = result[:resource][:cloudflare_load_balancer_pool][:web_pool]
      expect(pool[:monitor]).to eq("${cloudflare_load_balancer_monitor.http_monitor.id}")
    end
  end
end
