# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_worker_route/resource'

RSpec.describe 'cloudflare_worker_route synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    synthesizer = TerraformSynthesizer.new
    synthesizer.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_worker_route(:api, {
        zone_id: "0da42c8d2132a9ddaf714f9e7c920711",
        pattern: "api.example.com/*",
        script_name: "api-worker"
      })
    end

    result = synthesizer.synthesis
    route = result[:resource][:cloudflare_worker_route][:api]

    expect(route[:zone_id]).to eq("0da42c8d2132a9ddaf714f9e7c920711")
    expect(route[:pattern]).to eq("api.example.com/*")
    expect(route[:script_name]).to eq("api-worker")
  end
end
