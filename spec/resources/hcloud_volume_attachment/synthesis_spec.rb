# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_volume_attachment/resource'

RSpec.describe 'hcloud_volume_attachment synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes volume attachment' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_volume_attachment(:data_attach, {
        volume_id: "${hcloud_volume.data.id}",
        server_id: "${hcloud_server.web.id}",
        automount: true
      })
    end

    result = synthesizer.synthesis
    va = result[:resource][:hcloud_volume_attachment][:data_attach]

    expect(va[:volume_id]).to eq("${hcloud_volume.data.id}")
    expect(va[:server_id]).to eq("${hcloud_server.web.id}")
    expect(va[:automount]).to be true
  end
end
