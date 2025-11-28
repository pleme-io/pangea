# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_server_network/resource'

RSpec.describe 'hcloud_server_network synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes server network attachment' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_server_network(:web01_net, {
        server_id: "${hcloud_server.web01.id}",
        network_id: "${hcloud_network.private.id}",
        ip: "10.0.1.10"
      })
    end

    result = synthesizer.synthesis
    sn = result[:resource][:hcloud_server_network][:web01_net]

    expect(sn[:server_id]).to eq("${hcloud_server.web01.id}")
    expect(sn[:network_id]).to eq("${hcloud_network.private.id}")
    expect(sn[:ip]).to eq("10.0.1.10")
  end
end
