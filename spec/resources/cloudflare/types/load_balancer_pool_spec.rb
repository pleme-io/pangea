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


require_relative '../../../spec_helper'

RSpec.describe Pangea::Resources::Cloudflare::Types::LoadBalancerPoolAttributes do
  let(:account_id) { "a" * 32 }
  let(:origins) do
    [
      { name: "origin1", address: "192.0.2.1", enabled: true, weight: 1 },
      { name: "origin2", address: "192.0.2.2", enabled: true, weight: 1 }
    ]
  end

  describe "type validation and creation" do
    it "creates valid pool with required attributes" do
      pool_attrs = described_class.new(
        account_id: account_id,
        name: "production-pool",
        origins: origins
      )

      expect(pool_attrs.account_id).to eq(account_id)
      expect(pool_attrs.name).to eq("production-pool")
      expect(pool_attrs.origins.length).to eq(2)
      expect(pool_attrs.enabled).to be true  # default
      expect(pool_attrs.minimum_origins).to eq(1)  # default
    end

    it "creates pool with all attributes" do
      pool_attrs = described_class.new(
        account_id: account_id,
        name: "production-pool",
        origins: origins,
        description: "Production web servers",
        enabled: true,
        minimum_origins: 1,
        monitor: "monitor-id",
        notification_email: "ops@example.com",
        check_regions: ["WNAM", "ENAM"]
      )

      expect(pool_attrs.description).to eq("Production web servers")
      expect(pool_attrs.monitor).to eq("monitor-id")
      expect(pool_attrs.notification_email).to eq("ops@example.com")
      expect(pool_attrs.check_regions).to contain_exactly("WNAM", "ENAM")
    end

    it "requires at least one origin" do
      expect {
        described_class.new(
          account_id: account_id,
          name: "empty-pool",
          origins: []
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it "rejects minimum_origins exceeding actual origins" do
      expect {
        described_class.new(
          account_id: account_id,
          name: "invalid-pool",
          origins: origins,
          minimum_origins: 5
        )
      }.to raise_error(Dry::Struct::Error, /minimum_origins.*cannot exceed/)
    end
  end

  describe "computed properties" do
    it "counts origins correctly" do
      pool_attrs = described_class.new(
        account_id: account_id,
        name: "test-pool",
        origins: origins
      )

      expect(pool_attrs.origin_count).to eq(2)
    end

    it "identifies pools with monitors" do
      pool_with_monitor = described_class.new(
        account_id: account_id,
        name: "monitored-pool",
        origins: origins,
        monitor: "monitor-id"
      )

      pool_without_monitor = described_class.new(
        account_id: account_id,
        name: "unmonitored-pool",
        origins: origins
      )

      expect(pool_with_monitor.has_monitor?).to be true
      expect(pool_without_monitor.has_monitor?).to be false
    end

    it "identifies enabled pools" do
      enabled_pool = described_class.new(
        account_id: account_id,
        name: "enabled-pool",
        origins: origins,
        enabled: true
      )

      disabled_pool = described_class.new(
        account_id: account_id,
        name: "disabled-pool",
        origins: origins,
        enabled: false
      )

      expect(enabled_pool.is_enabled?).to be true
      expect(disabled_pool.is_enabled?).to be false
    end

    it "counts enabled origins correctly" do
      mixed_origins = [
        { name: "origin1", address: "192.0.2.1", enabled: true },
        { name: "origin2", address: "192.0.2.2", enabled: false },
        { name: "origin3", address: "192.0.2.3", enabled: true }
      ]

      pool_attrs = described_class.new(
        account_id: account_id,
        name: "mixed-pool",
        origins: mixed_origins
      )

      expect(pool_attrs.enabled_origin_count).to eq(2)
    end
  end

  describe "real-world usage scenarios" do
    it "supports typical production pool configuration" do
      production_pool = described_class.new(
        account_id: account_id,
        name: "production-web-servers",
        description: "Production web server pool with health monitoring",
        origins: [
          { name: "web1", address: "192.0.2.1", enabled: true, weight: 1 },
          { name: "web2", address: "192.0.2.2", enabled: true, weight: 1 },
          { name: "web3", address: "192.0.2.3", enabled: true, weight: 1 }
        ],
        enabled: true,
        minimum_origins: 2,
        monitor: "http-monitor-id",
        notification_email: "ops@example.com",
        check_regions: ["WNAM", "ENAM", "WEU", "EEU"]
      )

      expect(production_pool.origin_count).to eq(3)
      expect(production_pool.has_monitor?).to be true
      expect(production_pool.is_enabled?).to be true
      expect(production_pool.enabled_origin_count).to eq(3)
    end

    it "supports geo-distributed pool with regional health checks" do
      global_pool = described_class.new(
        account_id: account_id,
        name: "global-cdn-pool",
        origins: [
          { name: "us-east", address: "192.0.2.1" },
          { name: "us-west", address: "192.0.2.2" },
          { name: "eu-west", address: "192.0.2.3" },
          { name: "ap-southeast", address: "192.0.2.4" }
        ],
        minimum_origins: 2,
        check_regions: ["WNAM", "ENAM", "WEU", "SEAS"]
      )

      expect(global_pool.origin_count).to eq(4)
      expect(global_pool.check_regions.length).to eq(4)
    end
  end
end
