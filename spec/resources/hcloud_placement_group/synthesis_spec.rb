# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_placement_group/resource'

RSpec.describe 'hcloud_placement_group synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes placement group' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_placement_group(:spread, {
        name: "production-spread",
        type: "spread"
      })
    end

    result = synthesizer.synthesis
    pg = result[:resource][:hcloud_placement_group][:spread]

    expect(pg[:name]).to eq("production-spread")
    expect(pg[:type]).to eq("spread")
  end
end
