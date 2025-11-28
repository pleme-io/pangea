# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_api_shield_schema/resource'

RSpec.describe 'cloudflare_api_shield_schema synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_api_shield_schema(:test, {
        zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        name: "my-api-schema",
        source: "openapi: 3.0.0..."
      })
    end
  end
end
