# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_volume/resource'

RSpec.describe 'hcloud_volume synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes volume' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_volume(:data, {
        name: "web-data",
        size: 100,
        location: "fsn1",
        format: "ext4"
      })
    end

    result = synthesizer.synthesis
    volume = result[:resource][:hcloud_volume][:data]

    expect(volume[:name]).to eq("web-data")
    expect(volume[:size]).to eq(100)
    expect(volume[:location]).to eq("fsn1")
    expect(volume[:format]).to eq("ext4")
  end
end
