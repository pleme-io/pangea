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
require 'pangea/resources/cloudflare_spectrum_application/resource'
require 'pangea/resources/cloudflare_spectrum_application/types'

RSpec.describe 'cloudflare_spectrum_application synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:zone_id) { "023e105f4ecef8ad9ca31a8372d0c353" }

  it 'synthesizes SSH spectrum application' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_spectrum_application(:ssh, {
        zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        protocol: "tcp/22",
        dns_name: "ssh.example.com",
        origin_direct: ["tcp://192.0.2.1:22"]
      })
    end

    result = synthesizer.synthesis
    app = result[:resource][:cloudflare_spectrum_application][:ssh]

    expect(app[:protocol]).to eq("tcp/22")
    expect(app[:dns][:name]).to eq("ssh.example.com")
    expect(app[:origin_direct]).to eq(["tcp://192.0.2.1:22"])
  end

  it 'synthesizes gaming server with port range' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_spectrum_application(:game, {
        zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        protocol: "udp/27015-27020",
        dns_name: "game.example.com",
        origin_dns_name: "origin.example.com",
        origin_port: 27015
      })
    end

    result = synthesizer.synthesis
    app = result[:resource][:cloudflare_spectrum_application][:game]

    expect(app[:protocol]).to eq("udp/27015-27020")
    expect(app[:origin_dns][:name]).to eq("origin.example.com")
    expect(app[:origin_port]).to eq(27015)
  end
end
