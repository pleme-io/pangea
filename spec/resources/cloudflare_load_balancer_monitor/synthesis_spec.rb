# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_load_balancer_monitor/resource'

RSpec.describe 'cloudflare_load_balancer_monitor synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    synthesizer = TerraformSynthesizer.new
    synthesizer.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_load_balancer_monitor(:test, {
        account_id: "f037e56e89293a057740de681ac9abbe",
        type: "http",
        method: "GET"
      })
    end

    result = synthesizer.synthesis
    monitor = result[:resource][:cloudflare_load_balancer_monitor][:test]

    expect(monitor[:account_id]).to eq("f037e56e89293a057740de681ac9abbe")
    expect(monitor[:type]).to eq("http")
    expect(monitor[:method]).to eq("GET")
  end
end
