# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_managed_certificate/resource'

RSpec.describe 'hcloud_managed_certificate synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes managed certificate' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_managed_certificate(:le_cert, {
        name: "letsencrypt-cert",
        domain_names: ["example.com", "www.example.com"]
      })
    end

    result = synthesizer.synthesis
    mc = result[:resource][:hcloud_managed_certificate][:le_cert]

    expect(mc[:name]).to eq("letsencrypt-cert")
    expect(mc[:domain_names]).to eq(["example.com", "www.example.com"])
  end
end
