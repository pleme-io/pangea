# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_floating_ip_assignment/resource'

RSpec.describe 'hcloud_floating_ip_assignment synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes floating IP assignment' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_floating_ip_assignment(:lb_ip_assign, {
        floating_ip_id: "${hcloud_floating_ip.lb_ip.id}",
        server_id: "${hcloud_server.lb.id}"
      })
    end

    result = synthesizer.synthesis
    fia = result[:resource][:hcloud_floating_ip_assignment][:lb_ip_assign]

    expect(fia[:floating_ip_id]).to eq("${hcloud_floating_ip.lb_ip.id}")
    expect(fia[:server_id]).to eq("${hcloud_server.lb.id}")
  end
end
