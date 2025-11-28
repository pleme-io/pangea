# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_load_balancer/resource'

RSpec.describe 'hcloud_load_balancer synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes load balancer' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_load_balancer(:app_lb, {
        name: "app-load-balancer",
        load_balancer_type: "lb11",
        location: "fsn1"
      })
    end

    result = synthesizer.synthesis
    lb = result[:resource][:hcloud_load_balancer][:app_lb]

    expect(lb[:name]).to eq("app-load-balancer")
    expect(lb[:load_balancer_type]).to eq("lb11")
    expect(lb[:location]).to eq("fsn1")
  end
end
