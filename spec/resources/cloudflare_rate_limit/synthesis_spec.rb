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
require 'pangea/resources/cloudflare_rate_limit/resource'
require 'pangea/resources/cloudflare_rate_limit/types'

RSpec.describe 'cloudflare_rate_limit synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:zone_id) { "023e105f4ecef8ad9ca31a8372d0c353" }

  it 'synthesizes basic rate limit' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_rate_limit(:api_limit, {
        zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        threshold: 100,
        period: 60,
        action_mode: "challenge"
      })
    end

    result = synthesizer.synthesis
    rl = result[:resource][:cloudflare_rate_limit][:api_limit]

    expect(rl[:threshold]).to eq(100)
    expect(rl[:period]).to eq(60)
    expect(rl[:action][:mode]).to eq("challenge")
  end

  it 'synthesizes rate limit with match criteria' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_rate_limit(:login_limit, {
        zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        threshold: 5,
        period: 300,
        action_mode: "ban",
        action_timeout: 600,
        match_request_url: "*/login",
        match_request_methods: ["POST"]
      })
    end

    result = synthesizer.synthesis
    rl = result[:resource][:cloudflare_rate_limit][:login_limit]

    expect(rl[:threshold]).to eq(5)
    expect(rl[:period]).to eq(300)
    expect(rl[:action][:mode]).to eq("ban")
    expect(rl[:action][:timeout]).to eq(600)
  end
end
