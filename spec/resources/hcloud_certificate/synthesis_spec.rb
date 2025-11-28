# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_certificate/resource'

RSpec.describe 'hcloud_certificate synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes certificate' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_certificate(:ssl_cert, {
        name: "ssl-certificate",
        certificate: "-----BEGIN CERTIFICATE-----\n...",
        private_key: "-----BEGIN PRIVATE KEY-----\n..."
      })
    end

    result = synthesizer.synthesis
    cert = result[:resource][:hcloud_certificate][:ssl_cert]

    expect(cert[:name]).to eq("ssl-certificate")
  end
end
