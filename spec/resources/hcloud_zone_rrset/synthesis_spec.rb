# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_zone_rrset/resource'

RSpec.describe 'hcloud_zone_rrset synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes DNS record set' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_zone_rrset(:web_a_record, {
        zone_id: "${hcloud_zone.primary_zone.id}",
        name: "www",
        type: "A",
        values: ["192.0.2.1", "192.0.2.2"],
        ttl: 3600
      })
    end

    result = synthesizer.synthesis
    rrset = result[:resource][:hcloud_zone_rrset][:web_a_record]

    expect(rrset[:zone_id]).to eq("${hcloud_zone.primary_zone.id}")
    expect(rrset[:name]).to eq("www")
    expect(rrset[:type]).to eq("A")
    expect(rrset[:values]).to eq(["192.0.2.1", "192.0.2.2"])
    expect(rrset[:ttl]).to eq(3600)
  end
end
