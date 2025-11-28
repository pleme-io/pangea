# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_floating_ip/resource'

RSpec.describe 'hcloud_floating_ip synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes floating IP' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_floating_ip(:lb_ip, {
        type: "ipv4",
        home_location: "fsn1",
        description: "Load balancer public IP"
      })
    end

    result = synthesizer.synthesis
    fip = result[:resource][:hcloud_floating_ip][:lb_ip]

    expect(fip[:type]).to eq("ipv4")
    expect(fip[:home_location]).to eq("fsn1")
  end
end
