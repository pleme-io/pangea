# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_firewall_attachment/resource'

RSpec.describe 'hcloud_firewall_attachment synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes firewall attachment' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_firewall_attachment(:web_fw_attach, {
        firewall_id: "${hcloud_firewall.web.id}",
        server_ids: ["${hcloud_server.web01.id}", "${hcloud_server.web02.id}"]
      })
    end

    result = synthesizer.synthesis
    fa = result[:resource][:hcloud_firewall_attachment][:web_fw_attach]

    expect(fa[:firewall_id]).to eq("${hcloud_firewall.web.id}")
  end
end
