# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_load_balancer_target/resource'

RSpec.describe 'hcloud_load_balancer_target synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes load balancer target' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_load_balancer_target(:target1, {
        load_balancer_id: "${hcloud_load_balancer.app_lb.id}",
        type: "server",
        server_id: "${hcloud_server.web01.id}",
        use_private_ip: true
      })
    end

    result = synthesizer.synthesis
    lbt = result[:resource][:hcloud_load_balancer_target][:target1]

    expect(lbt[:type]).to eq("server")
    expect(lbt[:use_private_ip]).to be true
  end
end
