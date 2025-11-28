# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/hcloud_load_balancer_service/resource'

RSpec.describe 'hcloud_load_balancer_service synthesis' do
  include Pangea::Resources::Hetzner

  let(:synthesizer) { TerraformSynthesizer.new }

  it 'synthesizes load balancer service' do
    synthesizer.instance_eval do
      extend Pangea::Resources::Hetzner
      hcloud_load_balancer_service(:http, {
        load_balancer_id: "${hcloud_load_balancer.app_lb.id}",
        protocol: "http",
        listen_port: 80,
        destination_port: 80
      })
    end

    result = synthesizer.synthesis
    lbs = result[:resource][:hcloud_load_balancer_service][:http]

    expect(lbs[:protocol]).to eq("http")
    expect(lbs[:listen_port]).to eq(80)
  end
end
