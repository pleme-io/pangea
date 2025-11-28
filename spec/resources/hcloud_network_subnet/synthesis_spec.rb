# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_network_subnet/resource'

RSpec.describe 'hcloud_network_subnet synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes basic subnet' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_network_subnet(:subnet, {
        network_id: "${hcloud_network.private.id}",
        type: "cloud",
        network_zone: "eu-central",
        ip_range: "10.0.1.0/24"
      })
    end

    result = synthesizer.synthesis
    subnet = result[:resource][:hcloud_network_subnet][:subnet]

    expect(subnet[:network_id]).to eq("${hcloud_network.private.id}")
    expect(subnet[:type]).to eq("cloud")
    expect(subnet[:network_zone]).to eq("eu-central")
    expect(subnet[:ip_range]).to eq("10.0.1.0/24")
  end
end
