# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_network_route/resource'

RSpec.describe 'hcloud_network_route synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes network route' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_network_route(:custom_route, {
        network_id: "${hcloud_network.private.id}",
        destination: "10.100.0.0/16",
        gateway: "10.0.1.1"
      })
    end

    result = synthesizer.synthesis
    route = result[:resource][:hcloud_network_route][:custom_route]

    expect(route[:network_id]).to eq("${hcloud_network.private.id}")
    expect(route[:destination]).to eq("10.100.0.0/16")
    expect(route[:gateway]).to eq("10.0.1.1")
  end
end
