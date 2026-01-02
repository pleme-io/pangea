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
require 'pangea/resources/cloudflare_filter/resource'

RSpec.describe 'cloudflare_filter synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic filter' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_filter(:block_bots, {
          zone_id: '0da42c8d2132a9ddaf714f9e7c920711',
          expression: '(cf.client.bot)'
        })
      end

      result = synthesizer.synthesis
      filter = result[:resource][:cloudflare_filter][:block_bots]

      expect(filter[:zone_id]).to eq('0da42c8d2132a9ddaf714f9e7c920711')
      expect(filter[:expression]).to eq('(cf.client.bot)')
    end

    it 'synthesizes filter with description' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_filter(:rate_limit_filter, {
          zone_id: '0da42c8d2132a9ddaf714f9e7c920711',
          expression: '(http.request.uri.path contains "/api/")',
          description: 'Filter for API rate limiting'
        })
      end

      result = synthesizer.synthesis
      filter = result[:resource][:cloudflare_filter][:rate_limit_filter]

      expect(filter[:description]).to eq('Filter for API rate limiting')
    end

    it 'synthesizes paused filter' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_filter(:paused_filter, {
          zone_id: '0da42c8d2132a9ddaf714f9e7c920711',
          expression: '(ip.src eq 192.168.1.1)',
          paused: true
        })
      end

      result = synthesizer.synthesis
      filter = result[:resource][:cloudflare_filter][:paused_filter]

      expect(filter[:paused]).to be true
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_filter(:test, {
          zone_id: '0da42c8d2132a9ddaf714f9e7c920711',
          expression: '(cf.threat_score gt 10)'
        })
      end

      expect(ref.outputs[:id]).to eq('${cloudflare_filter.test.id}')
    end
  end
end
