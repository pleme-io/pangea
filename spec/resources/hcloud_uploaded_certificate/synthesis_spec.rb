# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_uploaded_certificate/resource'

RSpec.describe 'hcloud_uploaded_certificate synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes uploaded certificate' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_uploaded_certificate(:ssl_cert, {
        name: "example.com-ssl",
        certificate: "-----BEGIN CERTIFICATE-----\nMIIC...\n-----END CERTIFICATE-----",
        private_key: "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----",
        labels: { "env" => "production" }
      })
    end

    result = synthesizer.synthesis
    cert = result[:resource][:hcloud_uploaded_certificate][:ssl_cert]

    expect(cert[:name]).to eq("example.com-ssl")
    expect(cert[:certificate]).to include("BEGIN CERTIFICATE")
    expect(cert[:private_key]).to include("BEGIN PRIVATE KEY")
    expect(cert[:labels]).to eq({ "env" => "production" })
  end
end
