# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_network/resource'

RSpec.describe 'hcloud_network synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes basic network' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_network(:private, {
        name: "private-network",
        ip_range: "10.0.0.0/16"
      })
    end

    result = synthesizer.synthesis
    network = result[:resource][:hcloud_network][:private]

    expect(network[:name]).to eq("private-network")
    expect(network[:ip_range]).to eq("10.0.0.0/16")
  end

  it 'synthesizes network with labels' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_network(:private, {
        name: "private-network",
        ip_range: "10.0.0.0/16",
        labels: { environment: "production" }
      })
    end

    result = synthesizer.synthesis
    network = result[:resource][:hcloud_network][:private]

    expect(network[:labels][:environment]).to eq("production")
  end
end
