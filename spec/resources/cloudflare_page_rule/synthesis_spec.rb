# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_page_rule/resource'

RSpec.describe 'cloudflare_page_rule synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:zone_id) { "0da42c8d2132a9ddaf714f9e7c920711" }

  it 'synthesizes basic page rule with cache settings' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_page_rule(:cache_everything, {
        zone_id: "0da42c8d2132a9ddaf714f9e7c920711",
        target: "*.example.com/*",
        actions: {
          cache_level: "cache_everything",
          edge_cache_ttl: 7200
        }
      })
    end

    result = synthesizer.synthesis
    rule = result[:resource][:cloudflare_page_rule][:cache_everything]

    expect(rule[:zone_id]).to eq(zone_id)
    expect(rule[:target]).to eq("*.example.com/*")
    expect(rule[:actions]).to include(cache_level: "cache_everything", edge_cache_ttl: 7200)
    expect(rule[:priority]).to eq(1)
    expect(rule[:status]).to eq("active")
  end
end
