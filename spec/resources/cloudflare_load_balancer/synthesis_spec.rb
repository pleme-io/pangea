# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_load_balancer/resource'

RSpec.describe 'cloudflare_load_balancer synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    synthesizer = TerraformSynthesizer.new
    synthesizer.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_load_balancer(:test, {
        zone_id: "0da42c8d2132a9ddaf714f9e7c920711",
        name: "lb.example.com",
        default_pool_ids: ["pool1", "pool2"]
      })
    end

    result = synthesizer.synthesis
    lb = result[:resource][:cloudflare_load_balancer][:test]

    expect(lb[:zone_id]).to eq("0da42c8d2132a9ddaf714f9e7c920711")
    expect(lb[:name]).to eq("lb.example.com")
  end
end
