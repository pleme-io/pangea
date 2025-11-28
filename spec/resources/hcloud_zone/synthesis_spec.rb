# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_zone/resource'

RSpec.describe 'hcloud_zone synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes DNS zone' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_zone(:primary_zone, {
        name: "example.com",
        ttl: 3600
      })
    end

    result = synthesizer.synthesis
    zone = result[:resource][:hcloud_zone][:primary_zone]

    expect(zone[:name]).to eq("example.com")
    expect(zone[:ttl]).to eq(3600)
  end
end
