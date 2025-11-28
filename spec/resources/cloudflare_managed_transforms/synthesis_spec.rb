# frozen_string_literal: true
require 'spec_helper'
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_managed_transforms/resource'

RSpec.describe 'cloudflare_managed_transforms synthesis' do
  include Pangea::Resources::Cloudflare
  it 'synthesizes managed transforms' do
    TerraformSynthesizer.new.instance_eval do
      extend Pangea::Resources::Cloudflare
      cloudflare_managed_transforms(:transforms, {
        zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
        managed_request_headers: { "add_bot_protection_headers" => true }
      })
    end
  end
end
