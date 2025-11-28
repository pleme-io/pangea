# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_primary_ip/resource'

RSpec.describe 'hcloud_primary_ip synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes primary IP' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_primary_ip(:production_ip, {
        name: "production-primary-ip",
        type: "ipv4",
        assignee_type: "server",
        datacenter: "fsn1-dc14",
        auto_delete: false
      })
    end

    result = synthesizer.synthesis
    pip = result[:resource][:hcloud_primary_ip][:production_ip]

    expect(pip[:type]).to eq("ipv4")
    expect(pip[:auto_delete]).to be false
  end
end
