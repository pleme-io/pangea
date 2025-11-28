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
require 'pangea/resources/cloudflare_zone/resource'
require 'pangea/resources/cloudflare_zone/types'

RSpec.describe 'cloudflare_zone synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic free zone' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_zone(:example, {
          zone: "example.com"
        })
      end

      result = synthesizer.synthesis
      zone = result[:resource][:cloudflare_zone][:example]

      expect(zone).to include(
        zone: "example.com",
        jump_start: false,
        paused: false,
        plan: "free",
        type: "full"
      )
      expect(zone).not_to have_key(:account_id)
    end

    it 'synthesizes pro zone with account' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_zone(:production, {
          zone: "example.com",
          account_id: "f" * 32,
          plan: "pro",
          jump_start: true
        })
      end

      result = synthesizer.synthesis
      zone = result[:resource][:cloudflare_zone][:production]

      expect(zone[:zone]).to eq("example.com")
      expect(zone[:account_id]).to eq("f" * 32)
      expect(zone[:plan]).to eq("pro")
      expect(zone[:jump_start]).to be true
    end

    it 'synthesizes partial zone for CNAME setup' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_zone(:saas_zone, {
          zone: "shop.example.com",
          type: "partial",
          plan: "business"
        })
      end

      result = synthesizer.synthesis
      zone = result[:resource][:cloudflare_zone][:saas_zone]

      expect(zone[:type]).to eq("partial")
      expect(zone[:plan]).to eq("business")
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_zone(:test, { zone: "test.com" })
      end

      expect(ref.id).to eq("${cloudflare_zone.test.id}")
      expect(ref.outputs[:zone_id]).to eq("${cloudflare_zone.test.id}")
      expect(ref.outputs[:status]).to eq("${cloudflare_zone.test.status}")
      expect(ref.outputs[:name_servers]).to eq("${cloudflare_zone.test.name_servers}")
    end
  end
end
