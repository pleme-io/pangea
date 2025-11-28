# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_rdns/resource'

RSpec.describe 'hcloud_rdns synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes reverse DNS' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_rdns(:server_rdns, {
        server_id: "${hcloud_server.production.id}",
        ip_address: "${hcloud_server.production.ipv4_address}",
        dns_ptr: "production.example.com"
      })
    end

    result = synthesizer.synthesis
    rdns = result[:resource][:hcloud_rdns][:server_rdns]

    expect(rdns[:dns_ptr]).to eq("production.example.com")
  end
end
