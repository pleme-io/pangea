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
require 'pangea/resources/cloudflare_regional_tiered_cache/resource'
require 'pangea/resources/cloudflare_regional_tiered_cache/types'

RSpec.describe 'cloudflare_regional_tiered_cache synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:zone_id) { "023e105f4ecef8ad9ca31a8372d0c353" }

  describe 'terraform synthesis' do
    it 'synthesizes with regional tiered cache enabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_regional_tiered_cache(:regional_cache, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          value: "on"
        })
      end

      result = synthesizer.synthesis
      cache = result[:resource][:cloudflare_regional_tiered_cache][:regional_cache]

      expect(cache[:zone_id]).to eq(zone_id)
      expect(cache[:value]).to eq("on")
    end

    it 'synthesizes with regional tiered cache disabled' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_regional_tiered_cache(:regional_cache_off, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          value: "off"
        })
      end

      result = synthesizer.synthesis
      cache = result[:resource][:cloudflare_regional_tiered_cache][:regional_cache_off]

      expect(cache[:zone_id]).to eq(zone_id)
      expect(cache[:value]).to eq("off")
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_regional_tiered_cache(:test, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          value: "on"
        })
      end

      expect(ref.id).to eq("${cloudflare_regional_tiered_cache.test.id}")
      expect(ref.outputs[:editable]).to eq("${cloudflare_regional_tiered_cache.test.editable}")
      expect(ref.outputs[:modified_on]).to eq("${cloudflare_regional_tiered_cache.test.modified_on}")
    end
  end

  describe 'helper methods' do
    it 'identifies enabled state' do
      attrs = Cloudflare::Types::RegionalTieredCacheAttributes.new(
        zone_id: zone_id,
        value: "on"
      )

      expect(attrs.enabled?).to be true
      expect(attrs.disabled?).to be false
    end

    it 'identifies disabled state' do
      attrs = Cloudflare::Types::RegionalTieredCacheAttributes.new(
        zone_id: zone_id,
        value: "off"
      )

      expect(attrs.enabled?).to be false
      expect(attrs.disabled?).to be true
    end
  end

  describe 'validation' do
    it 'rejects invalid values' do
      expect {
        Cloudflare::Types::RegionalTieredCacheAttributes.new(
          zone_id: zone_id,
          value: "invalid"
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe 'combined with smart tiered cache' do
    it 'can be used together with cloudflare_tiered_cache' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # Enable Smart Tiered Cache
        cloudflare_tiered_cache(:smart, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          value: "on"
        })

        # Enable Regional Tiered Cache
        cloudflare_regional_tiered_cache(:regional, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          value: "on"
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:cloudflare_tiered_cache]).to have_key(:smart)
      expect(result[:resource][:cloudflare_regional_tiered_cache]).to have_key(:regional)
    end
  end
end
