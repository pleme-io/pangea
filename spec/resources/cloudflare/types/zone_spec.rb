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

RSpec.describe Pangea::Resources::Cloudflare::Types::ZoneAttributes do
  describe "type validation and creation" do
    it "creates valid zone with required attributes" do
      zone_attrs = described_class.new(
        zone: "example.com"
      )

      expect(zone_attrs.zone).to eq("example.com")
      expect(zone_attrs.jump_start).to be false  # default
      expect(zone_attrs.paused).to be false  # default
      expect(zone_attrs.plan).to eq("free")  # default
      expect(zone_attrs.type).to eq("full")  # default
    end

    it "creates zone with all attributes" do
      zone_attrs = described_class.new(
        zone: "example.com",
        account_id: "a" * 32,
        jump_start: true,
        paused: false,
        plan: "pro",
        type: "full"
      )

      expect(zone_attrs.zone).to eq("example.com")
      expect(zone_attrs.account_id).to eq("a" * 32)
      expect(zone_attrs.jump_start).to be true
      expect(zone_attrs.paused).to be false
      expect(zone_attrs.plan).to eq("pro")
      expect(zone_attrs.type).to eq("full")
    end

    it "accepts all valid zone plans" do
      %w[free pro business enterprise].each do |plan|
        zone_attrs = described_class.new(
          zone: "example.com",
          plan: plan
        )
        expect(zone_attrs.plan).to eq(plan)
      end
    end

    it "accepts all valid zone types" do
      %w[full partial secondary].each do |type|
        zone_attrs = described_class.new(
          zone: "example.com",
          type: type
        )
        expect(zone_attrs.type).to eq(type)
      end
    end

    it "rejects invalid zone names" do
      expect {
        described_class.new(zone: "not a valid domain!")
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe "computed properties" do
    it "identifies active zones" do
      active_zone = described_class.new(zone: "example.com", paused: false)
      paused_zone = described_class.new(zone: "example.com", paused: true)

      expect(active_zone.is_active?).to be true
      expect(paused_zone.is_active?).to be false
    end

    it "identifies enterprise zones" do
      enterprise_zone = described_class.new(zone: "example.com", plan: "enterprise")
      free_zone = described_class.new(zone: "example.com", plan: "free")

      expect(enterprise_zone.is_enterprise?).to be true
      expect(free_zone.is_enterprise?).to be false
    end

    it "identifies free zones" do
      free_zone = described_class.new(zone: "example.com", plan: "free")
      pro_zone = described_class.new(zone: "example.com", plan: "pro")

      expect(free_zone.is_free?).to be true
      expect(pro_zone.is_free?).to be false
    end

    it "extracts root domain correctly" do
      root_zone = described_class.new(zone: "example.com")
      subdomain_zone = described_class.new(zone: "www.example.com")
      deep_subdomain_zone = described_class.new(zone: "api.staging.example.com")

      expect(root_zone.zone_root_domain).to eq("example.com")
      expect(subdomain_zone.zone_root_domain).to eq("example.com")
      expect(deep_subdomain_zone.zone_root_domain).to eq("example.com")
    end

    it "identifies subdomains" do
      root_zone = described_class.new(zone: "example.com")
      subdomain_zone = described_class.new(zone: "www.example.com")

      expect(root_zone.is_subdomain?).to be false
      expect(subdomain_zone.is_subdomain?).to be true
    end
  end

  describe "real-world usage scenarios" do
    it "supports typical production zone configuration" do
      production_zone = described_class.new(
        zone: "example.com",
        account_id: "f" * 32,
        jump_start: true,
        paused: false,
        plan: "business",
        type: "full"
      )

      expect(production_zone.is_active?).to be true
      expect(production_zone.is_subdomain?).to be false
      expect(production_zone.plan).to eq("business")
    end

    it "supports partial zone configuration for CNAME setup" do
      partial_zone = described_class.new(
        zone: "shop.example.com",
        type: "partial",
        plan: "free"
      )

      expect(partial_zone.type).to eq("partial")
      expect(partial_zone.is_subdomain?).to be true
    end
  end
end
