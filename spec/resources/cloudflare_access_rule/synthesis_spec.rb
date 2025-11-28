# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_access_rule/resource'
require 'pangea/resources/cloudflare_access_rule/types'

RSpec.describe 'cloudflare_access_rule synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes IP block rule at zone level' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_access_rule(:block_ip, {
        zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        mode: "block",
        target: "ip",
        value: "198.51.100.4"
      })
    end

    result = synthesizer.synthesis
    rule = result[:resource][:cloudflare_access_rule][:block_ip]

    expect(rule[:mode]).to eq("block")
    expect(rule[:configuration][:target]).to eq("ip")
    expect(rule[:configuration][:value]).to eq("198.51.100.4")
  end

  it 'synthesizes whitelist rule at account level' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_access_rule(:allow_office, {
        account_id: "a" * 32,
        mode: "whitelist",
        target: "ip_range",
        value: "192.0.2.0/24"
      })
    end

    result = synthesizer.synthesis
    rule = result[:resource][:cloudflare_access_rule][:allow_office]

    expect(rule[:mode]).to eq("whitelist")
    expect(rule[:configuration][:target]).to eq("ip_range")
  end
end
