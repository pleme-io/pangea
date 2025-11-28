# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_api_shield_operation/resource'

RSpec.describe 'cloudflare_api_shield_operation synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_api_shield_operation(:test, {
        zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        method: "GET",
        host: "api.example.com",
        endpoint: "/api/v1/users"
      })
    end
  end
end
