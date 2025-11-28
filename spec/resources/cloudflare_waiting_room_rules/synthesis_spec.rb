# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_waiting_room_rules/resource'

RSpec.describe 'cloudflare_waiting_room_rules synthesis' do
  include Pangea::Resources::Cloudflare
  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes waiting room rules' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_waiting_room_rules(:rules, {
        zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        waiting_room_id: "wait123",
        rules: [{
          expression: "http.request.uri.path contains \"/bypass\"",
          action: "bypass_waiting_room",
          description: "Bypass for API"
        }]
      })
    end

    result = synthesizer.synthesis
    rules = result[:resource][:cloudflare_waiting_room_rules][:rules]
    expect(rules[:rules]).to be_an(Array)
  end
end
