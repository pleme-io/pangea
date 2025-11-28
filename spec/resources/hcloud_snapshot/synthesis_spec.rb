# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_snapshot/resource'

RSpec.describe 'hcloud_snapshot synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes snapshot' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_snapshot(:backup, {
        server_id: "${hcloud_server.web01.id}",
        description: "Weekly backup",
        labels: { "type" => "backup" }
      })
    end

    result = synthesizer.synthesis
    snapshot = result[:resource][:hcloud_snapshot][:backup]

    expect(snapshot[:server_id]).to eq("${hcloud_server.web01.id}")
    expect(snapshot[:description]).to eq("Weekly backup")
    expect(snapshot[:labels]).to eq({ "type" => "backup" })
  end
end
