# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_firewall/resource'

RSpec.describe 'hcloud_firewall synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes basic firewall' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_firewall(:web, {
        name: "web-firewall",
        rules: [
          {
            direction: "in",
            protocol: "tcp",
            port: "80",
            source_ips: ["0.0.0.0/0"]
          }
        ]
      })
    end

    result = synthesizer.synthesis
    firewall = result[:resource][:hcloud_firewall][:web]

    expect(firewall[:name]).to eq("web-firewall")
  end
end
