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
require 'pangea/resources/cloudflare_firewall_rule/resource'

RSpec.describe 'cloudflare_firewall_rule synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic firewall rule' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_firewall_rule(:block_bots, {
          zone_id: '0da42c8d2132a9ddaf714f9e7c920711',
          filter_id: '${cloudflare_filter.block_bots.id}',
          action: 'block'
        })
      end

      result = synthesizer.synthesis
      rule = result[:resource][:cloudflare_firewall_rule][:block_bots]

      expect(rule[:zone_id]).to eq('0da42c8d2132a9ddaf714f9e7c920711')
      expect(rule[:filter_id]).to eq('${cloudflare_filter.block_bots.id}')
      expect(rule[:action]).to eq('block')
    end

    it 'synthesizes firewall rule with challenge action' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_firewall_rule(:challenge_suspicious, {
          zone_id: '0da42c8d2132a9ddaf714f9e7c920711',
          filter_id: '${cloudflare_filter.suspicious.id}',
          action: 'challenge',
          description: 'Challenge suspicious traffic'
        })
      end

      result = synthesizer.synthesis
      rule = result[:resource][:cloudflare_firewall_rule][:challenge_suspicious]

      expect(rule[:action]).to eq('challenge')
      expect(rule[:description]).to eq('Challenge suspicious traffic')
    end

    it 'synthesizes firewall rule with priority' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_firewall_rule(:high_priority, {
          zone_id: '0da42c8d2132a9ddaf714f9e7c920711',
          filter_id: '${cloudflare_filter.critical.id}',
          action: 'block',
          priority: 1
        })
      end

      result = synthesizer.synthesis
      rule = result[:resource][:cloudflare_firewall_rule][:high_priority]

      expect(rule[:priority]).to eq(1)
    end

    it 'synthesizes paused firewall rule' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_firewall_rule(:paused_rule, {
          zone_id: '0da42c8d2132a9ddaf714f9e7c920711',
          filter_id: '${cloudflare_filter.test.id}',
          action: 'allow',
          paused: true
        })
      end

      result = synthesizer.synthesis
      rule = result[:resource][:cloudflare_firewall_rule][:paused_rule]

      expect(rule[:paused]).to be true
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_firewall_rule(:test, {
          zone_id: '0da42c8d2132a9ddaf714f9e7c920711',
          filter_id: '${cloudflare_filter.test.id}',
          action: 'block'
        })
      end

      expect(ref.outputs[:id]).to eq('${cloudflare_firewall_rule.test.id}')
    end
  end
end
