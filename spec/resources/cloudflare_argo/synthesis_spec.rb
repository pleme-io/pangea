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
require 'pangea/resources/cloudflare_argo/resource'
require 'pangea/resources/cloudflare_argo/types'

RSpec.describe 'cloudflare_argo synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:zone_id) { "023e105f4ecef8ad9ca31a8372d0c353" }

  describe 'Smart Routing' do
    it 'synthesizes with Smart Routing enabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_argo(:smart_routing, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          smart_routing: "on"
        })
      end

      result = synthesizer.synthesis
      argo = result[:resource][:cloudflare_argo][:smart_routing]

      expect(argo[:zone_id]).to eq(zone_id)
      expect(argo[:smart_routing]).to eq("on")
    end

    it 'synthesizes with Smart Routing disabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_argo(:smart_routing_off, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          smart_routing: "off"
        })
      end

      result = synthesizer.synthesis
      argo = result[:resource][:cloudflare_argo][:smart_routing_off]

      expect(argo[:smart_routing]).to eq("off")
    end
  end

  describe 'Tiered Caching' do
    it 'synthesizes with Tiered Caching enabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_argo(:tiered_cache, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          tiered_caching: "on"
        })
      end

      result = synthesizer.synthesis
      argo = result[:resource][:cloudflare_argo][:tiered_cache]

      expect(argo[:zone_id]).to eq(zone_id)
      expect(argo[:tiered_caching]).to eq("on")
    end

    it 'synthesizes with Tiered Caching disabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_argo(:tiered_cache_off, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          tiered_caching: "off"
        })
      end

      result = synthesizer.synthesis
      argo = result[:resource][:cloudflare_argo][:tiered_cache_off]

      expect(argo[:tiered_caching]).to eq("off")
    end
  end

  describe 'Combined features' do
    it 'synthesizes with both features enabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_argo(:full_argo, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          smart_routing: "on",
          tiered_caching: "on"
        })
      end

      result = synthesizer.synthesis
      argo = result[:resource][:cloudflare_argo][:full_argo]

      expect(argo[:zone_id]).to eq(zone_id)
      expect(argo[:smart_routing]).to eq("on")
      expect(argo[:tiered_caching]).to eq("on")
    end

    it 'synthesizes with both features disabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_argo(:argo_disabled, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          smart_routing: "off",
          tiered_caching: "off"
        })
      end

      result = synthesizer.synthesis
      argo = result[:resource][:cloudflare_argo][:argo_disabled]

      expect(argo[:smart_routing]).to eq("off")
      expect(argo[:tiered_caching]).to eq("off")
    end

    it 'synthesizes with mixed feature states' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_argo(:mixed, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          smart_routing: "on",
          tiered_caching: "off"
        })
      end

      result = synthesizer.synthesis
      argo = result[:resource][:cloudflare_argo][:mixed]

      expect(argo[:smart_routing]).to eq("on")
      expect(argo[:tiered_caching]).to eq("off")
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_argo(:test, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          smart_routing: "on"
        })
      end

      expect(ref.id).to eq("${cloudflare_argo.test.id}")
    end
  end

  describe 'helper methods' do
    it 'identifies enabled Smart Routing' do
      attrs = Cloudflare::Types::ArgoAttributes.new(
        zone_id: zone_id,
        smart_routing: "on"
      )

      expect(attrs.smart_routing_enabled?).to be true
      expect(attrs.any_enabled?).to be true
    end

    it 'identifies enabled Tiered Caching' do
      attrs = Cloudflare::Types::ArgoAttributes.new(
        zone_id: zone_id,
        tiered_caching: "on"
      )

      expect(attrs.tiered_caching_enabled?).to be true
      expect(attrs.any_enabled?).to be true
    end

    it 'identifies all features enabled' do
      attrs = Cloudflare::Types::ArgoAttributes.new(
        zone_id: zone_id,
        smart_routing: "on",
        tiered_caching: "on"
      )

      expect(attrs.all_enabled?).to be true
    end
  end
end
