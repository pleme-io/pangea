# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_list/resource'
require 'pangea/resources/cloudflare_list/types'

RSpec.describe 'cloudflare_list synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes IP list' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_list(:blocked_ips, {
        account_id: "a" * 32,
        name: "blocked_ips",
        kind: "ip",
        description: "Blocked IP addresses"
      })
    end

    result = synthesizer.synthesis
    list = result[:resource][:cloudflare_list][:blocked_ips]

    expect(list[:kind]).to eq("ip")
    expect(list[:name]).to eq("blocked_ips")
  end
end
