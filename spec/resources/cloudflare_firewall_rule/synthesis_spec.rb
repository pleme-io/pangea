# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_firewall_rule/resource'

RSpec.describe 'cloudflare_firewall_rule synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_firewall_rule(:test, { zone_id: "0da42c8d2132a9ddaf714f9e7c920711" })
    end
  end
end
