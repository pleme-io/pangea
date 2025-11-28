# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_load_balancer_network/resource'

RSpec.describe 'hcloud_load_balancer_network synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes load balancer network attachment' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_load_balancer_network(:lb_network, {
        load_balancer_id: "${hcloud_load_balancer.app_lb.id}",
        network_id: "${hcloud_network.private.id}",
        ip: "10.0.1.5"
      })
    end

    result = synthesizer.synthesis
    lbn = result[:resource][:hcloud_load_balancer_network][:lb_network]

    expect(lbn[:load_balancer_id]).to eq("${hcloud_load_balancer.app_lb.id}")
    expect(lbn[:network_id]).to eq("${hcloud_network.private.id}")
    expect(lbn[:ip]).to eq("10.0.1.5")
  end
end
